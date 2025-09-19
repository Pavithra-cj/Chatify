//
//  EncryptionManager.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-09-16.
//
//  Provides end-to-end style encryption helpers for chat messages using
//  Curve25519 key agreement + AES.GCM symmetric encryption.
//  It stores the user's private key in the Keychain and the public key in Firestore
//  under the "user" document as field "publicKey".
//
//  Message documents contain the ciphertext in `message` plus metadata:
//  - isEncrypted: true
//  - senderPublicKey: Base64 public key of the sender
//  - recipientPublicKey: Base64 public key of the recipient
//  The same structure is written to both sender and recipient collections so each
//  side can derive the shared secret with their own private key and the *other* public key.

import Foundation
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import Security

final class EncryptionManager {
    static let shared = EncryptionManager()
    static let currentVersion = 1
    private init() {}
    
    private let servicePrefix = "com.chatify.encryption"
    
    // Public method to proactively generate & publish local key pair
    func ensureLocalKeyPairPublished(completion: ((Bool) -> Void)? = nil) {
        prepareKeyPairIfNeeded { pair in
            completion?(pair != nil)
        }
    }
    
    // MARK: - Public API
    
    struct EncryptionPayload {
        let ciphertext: String
        let senderPublicKey: String
        let recipientPublicKey: String
    }
    
    /// Ensures both local (current user) key pair and remote (recipient) public key exist, then encrypts.
    func encrypt(_ plaintext: String, to recipientId: String, completion: @escaping (EncryptionPayload?) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { completion(nil); return }
        prepareKeyPairIfNeeded { [weak self] senderKeyPair in
            guard let self, let senderKeyPair else { completion(nil); return }
            self.fetchPublicKey(for: recipientId) { recipientPub in
                guard let recipientPub else { completion(nil); return }
                do {
                    let payload = try self.performEncryption(plaintext: plaintext,
                                                              senderPrivate: senderKeyPair.privateKey,
                                                              senderPublicBase64: senderKeyPair.publicKeyBase64,
                                                              recipientPublicBase64: recipientPub,
                                                              currentUid: currentUid,
                                                              recipientId: recipientId)
                    completion(payload)
                } catch {
                    print("Encryption failed: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
    /// Decrypts a ciphertext using metadata stored with the message.
    func decrypt(ciphertext: String, from fromId: String, to toId: String, senderPublicKey: String, recipientPublicKey: String) -> String? {
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        guard let privateKey = loadPrivateKey(for: currentUid) else { return nil }
        // Decide which is the "other" public key
        let otherPublicBase64: String
        if currentUid == fromId {
            otherPublicBase64 = recipientPublicKey
        } else {
            otherPublicBase64 = senderPublicKey
        }
        do {
            let otherPubData = try decodeBase64(otherPublicBase64)
            let otherPubKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: otherPubData)
            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: otherPubKey)
            let symmetricKey = deriveSymmetricKey(sharedSecret: sharedSecret, idA: fromId, idB: toId)
            guard let cipherData = Data(base64Encoded: ciphertext) else { return nil }
            let sealed = try AES.GCM.SealedBox(combined: cipherData)
            let clear = try AES.GCM.open(sealed, using: symmetricKey)
            return String(data: clear, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Helpers
    
    private func performEncryption(plaintext: String,
                                    senderPrivate: Curve25519.KeyAgreement.PrivateKey,
                                    senderPublicBase64: String,
                                    recipientPublicBase64: String,
                                    currentUid: String,
                                    recipientId: String) throws -> EncryptionPayload {
        let recipientPubData = try decodeBase64(recipientPublicBase64)
        let recipientPubKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientPubData)
        let sharedSecret = try senderPrivate.sharedSecretFromKeyAgreement(with: recipientPubKey)
        let symmetricKey = deriveSymmetricKey(sharedSecret: sharedSecret, idA: currentUid, idB: recipientId)
        let sealed = try AES.GCM.seal(Data(plaintext.utf8), using: symmetricKey)
        guard let combined = sealed.combined else { throw EncryptionError.sealFailed }
        return EncryptionPayload(ciphertext: combined.base64EncodedString(),
                                 senderPublicKey: senderPublicBase64,
                                 recipientPublicKey: recipientPublicBase64)
    }
    
    private func deriveSymmetricKey(sharedSecret: SharedSecret, idA: String, idB: String) -> SymmetricKey {
        let ordered = [idA, idB].sorted().joined(separator: "|")
        let salt = Data((servicePrefix + ".salt").utf8)
        let info = Data(("ChatifyChatEncryptionV1|" + ordered).utf8)
        return sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                    salt: salt,
                                                    sharedInfo: info,
                                                    outputByteCount: 32)
    }
    
    // MARK: - Key Management
    
    private struct KeyPair { let privateKey: Curve25519.KeyAgreement.PrivateKey; let publicKeyBase64: String }
    
    private func prepareKeyPairIfNeeded(completion: @escaping (KeyPair?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { completion(nil); return }
        if let existing = loadPrivateKey(for: uid) {
            let pubBase64 = existing.publicKey.rawRepresentation.base64EncodedString()
            completion(KeyPair(privateKey: existing, publicKeyBase64: pubBase64))
            // Ensure Firestore has the public key (fire-and-forget)
            ensurePublicKeyInFirestore(uid: uid, pubBase64: pubBase64)
            return
        }
        // Generate new pair
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let pubBase64 = privateKey.publicKey.rawRepresentation.base64EncodedString()
        if storePrivateKey(privateKey, for: uid) {
            ensurePublicKeyInFirestore(uid: uid, pubBase64: pubBase64)
            completion(KeyPair(privateKey: privateKey, publicKeyBase64: pubBase64))
        } else {
            completion(nil)
        }
    }
    
    private func ensurePublicKeyInFirestore(uid: String, pubBase64: String) {
        let doc = Firestore.firestore().collection("user").document(uid)
        doc.getDocument { snapshot, _ in
            let existing = snapshot?.data()? ["publicKey"] as? String
            if existing == nil || existing?.isEmpty == true || existing != pubBase64 {
                doc.setData(["publicKey": pubBase64], merge: true)
            }
        }
    }
    
    private func fetchPublicKey(for uid: String, completion: @escaping (String?) -> Void) {
        Firestore.firestore().collection("user").document(uid).getDocument { snapshot, error in
            if let error = error { print("Fetch public key error: \(error)"); completion(nil); return }
            let pk = snapshot?.data()? ["publicKey"] as? String
            completion(pk)
        }
    }
    
    // MARK: - Keychain
    
    private func keychainAccount(for uid: String) -> String { "priv." + uid }
    private func legacyKeychainTag(for uid: String) -> Data { (servicePrefix + ".priv." + uid).data(using: .utf8)! }
    
    private func loadPrivateKey(for uid: String) -> Curve25519.KeyAgreement.PrivateKey? {
        // First try new generic password storage
        let gpQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicePrefix,
            kSecAttrAccount as String: keychainAccount(for: uid),
            kSecReturnData as String: true
        ]
        if let data = SecItemCopyMatching(gpQuery as CFDictionary, nil) as? Data {
            return try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
        } else {
            var item: CFTypeRef?
            let status = SecItemCopyMatching(gpQuery as CFDictionary, &item)
            if status == errSecSuccess, let data = item as? Data { return try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data) }
        }
        // Fallback legacy retrieval for backward compatibility
        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: legacyKeychainTag(for: uid),
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnData as String: true
        ]
        var legacyItem: CFTypeRef?
        let legacyStatus = SecItemCopyMatching(legacyQuery as CFDictionary, &legacyItem)
        if legacyStatus == errSecSuccess, let data = legacyItem as? Data {
            // Migrate to new storage
            if let key = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data) {
                _ = storePrivateKey(key, for: uid)
                return key
            }
        }
        return nil
    }
    
    private func storePrivateKey(_ key: Curve25519.KeyAgreement.PrivateKey, for uid: String) -> Bool {
        let data = key.rawRepresentation
        // Delete any existing generic password entry
        let delGP: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicePrefix,
            kSecAttrAccount as String: keychainAccount(for: uid)
        ]
        SecItemDelete(delGP as CFDictionary)
        // Add new generic password entry
        let add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicePrefix,
            kSecAttrAccount as String: keychainAccount(for: uid),
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemAdd(add as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Utilities
    private enum EncryptionError: Error { case sealFailed; case decoding }
    private func decodeBase64(_ base64: String) throws -> Data { guard let d = Data(base64Encoded: base64) else { throw EncryptionError.decoding }; return d }
}
