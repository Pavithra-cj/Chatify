# Chatify

A modern SwiftUI Firebase-powered messaging app featuring real-time chat, end-to-end style encryption, biometric unlock, QR friend onboarding, push notifications, and modular feature-driven architecture.

## Table of Contents
- Features
- Tech Stack
- Architecture
- Data Model (High Level)
- End-to-End Style Encryption
- Push Notifications & Deep Links
- Biometric Authentication
- QR Code & Scanner
- Project Structure
- Getting Started
- Environment & Configuration
- Running & Testing
- Coding Conventions
- Roadmap / Ideas
- Security Notes
- Troubleshooting
- Contributing
- License

## Features
- SwiftUI UI with feature-based modules
- Email/password authentication (Firebase Auth)
- Biometric re-auth gate (Face ID / Touch ID) with session grace window
- Real-time messaging (Firestore) with recent message list
- Curve25519 + AES.GCM message encryption helper layer (per-conversation derived keys)
- Key storage: Private keys in iOS Keychain; public keys synced to Firestore user document
- Friend system & pending requests (push notification deep link support)
- Status updates (ephemeral / display views)
- QR code generation & scanning to add friends quickly
- FCM push notifications for messages & friend requests; local fallback notifications if needed
- Coordinator pattern for navigation & remote notification deep links
- CoreData `PersistenceController` placeholder (optionally for caching/local persistence)

## Tech Stack
- Language: Swift (iOS 16+ target recommended)
- UI: SwiftUI
- Backend: Firebase (Auth, Firestore, Cloud Messaging)
- Crypto: CryptoKit (Curve25519 key agreement, AES.GCM, HKDF)
- Notifications: APNs via FCM + UNUserNotificationCenter
- Device Services: LocalAuthentication (biometrics), AVFoundation / camera (QR scanning)

## Architecture
Feature-first modular layout under `Feature/`:
- Each feature has `View/` & `ViewModel/` subfolders
- Shared coordinative logic in `Core/AppCoordinator.swift`
- Utilities in `Util/` (encryption, biometric auth, Firebase constants, QR generation)
- Models in `Model/` separated from feature logic for reuse

Patterns:
- MVVM with lightweight ObservableObject view models
- Coordinator (AppCoordinator) for cross-feature navigation & deep links
- Reactive updates using Firestore listeners (implied in view models)
- Singletons only where stateful system services justify (EncryptionManager, AppCoordinator)

## Data Model (High Level)
Collections (indicative):
- `user` documents: profile, `publicKey`, `fcmToken`, historical `fcmTokens`
- `messages` or user-scoped subcollections: encrypted chat payloads with metadata
- `recent_messages` (denormalized latest snippets for list performance)
- `friend_requests` / friend relationship mapping
- `status` for ephemeral or broadcast user states

Message document fields (encrypted):
- `message`: Base64 ciphertext
- `isEncrypted`: true
- `senderPublicKey`, `recipientPublicKey`
- `fromId`, `toId`, timestamps, etc.

## End-to-End Style Encryption
Implemented in `EncryptionManager`:
- Generates Curve25519 key pair per user; private key stored in Keychain (Generic Password, `AfterFirstUnlockThisDeviceOnly`)
- Public key placed in Firestore `user.publicKey`
- For each message: derive a symmetric key using HKDF(sharedSecret, ordered user IDs) -> 32-byte AES key
- Encrypt plaintext with AES.GCM; store combined sealed box Base64
- Decrypt by recomputing shared secret locally (no private keys leave device)

Limitations / Notes:
- Not audited; treat as educational scaffold
- No forward secrecy per-message key rotation yet
- No signature / authenticity layer beyond key agreement

## Push Notifications & Deep Links
- FCM registration token stored & historical tokens appended (`fcmTokens` array)
- Remote notification payloads with `type` (e.g. `message`, `friend_request`)
- `AppCoordinator` interprets and sets published deep link state (`deepLinkTargetChatUserId`, `showFriendRequestsFromNotification`)
- Local notification fallback triggers if incoming payload lacks APNs `aps`

## Biometric Authentication
`BiometricAuthManager`:
- Detects available modality (Face ID / Touch ID)
- Maintains a short validity window (default 5 minutes) to avoid frequent prompts
- Persists last success timestamp in `UserDefaults`
- Provides `authenticate(completion:)` for gating sensitive UI (e.g. opening chats)

## QR Code & Scanner
- `QRCodeGenerator` creates codes embedding user identifiers
- `QRCodeScannerView` / related UIKit bridge handles camera scanning & delegate to view model
- Supports friend add flows via scanned user ID

## Project Structure
```
Chatify/
  ChatifyApp.swift
  Core/
    AppCoordinator.swift
    UI/ (shared UI components: auth fields, pickers, location manager)
  Feature/
    Auth/ ...
    MainMessages/
    ChatLog/
    Friends/
    CreateNewMessage/
    QRCode/
    QRCodeScanner/
    Settings/
    Status/
  Model/
  Util/
  Assets.xcassets/
  Chatify.xcdatamodeld/
  Tests/
```

## Getting Started
Prerequisites:
- Xcode 15+
- CocoaPods or Swift Package Manager (Firebase via SPM recommended)
- A Firebase project (iOS App registered) with: Auth (Email/Password), Firestore, Cloud Messaging enabled

Steps:
1. Clone repository:
   `git clone https://github.com/<your-org>/Chatify.git`
2. Open Workspace / Project in Xcode.
3. Add your `GoogleService-Info.plist`. Replace with your project's version.
4. In Firebase console: upload APNs key / certificates for Messaging.
5. Ensure push capability enabled in Signing & Capabilities.
6. Build & run on a real device (APNs + biometrics require device; simulator limited).

## Environment & Configuration
Sensitive or environment-specific items to externalize:
- Firebase plist
- Optional: Create `Config.xcconfig` for bundle IDs, feature flags
- Consider storing encryption feature flags (e.g. future toggle) in Remote Config

## Running & Testing
- Unit tests: `ChatifyTests/` (add coverage for encryption & biometric session logic)
- UI tests: `ChatifyUITests/`
- Suggested new tests:
  - Encryption round trip (plaintext -> encrypt -> decrypt == plaintext)
  - Key regeneration persists across app relaunch
  - Deep link notification handling populates coordinator state

## Coding Conventions
- Swift 5.9+; prefer struct for value models, final class for managers
- MVVM naming: `FooView`, `FooViewModel`
- Use dependency injection where expansion expected; singletons acceptable for Firebase & crypto baseline
- Avoid storing secrets in source; rely on Keychain or dynamic config

## Roadmap / Ideas
- Per-message ephemeral keys / double-ratchet style evolution
- Message signing to mitigate MITM of public keys
- Media (image/video) encrypted attachments
- Presence & typing indicators
- In-app settings for encryption version migration
- Offline caching & message queueing
- Multi-device key synchronization securely (secure enclave + iCloud Keychain?)

## Security Notes
This project implements a simplified E2EE model; before production:
- Perform formal security review
- Add key authenticity (signature / verification or trust-on-first-use pinning)
- Handle key rotation & revocation
- Consider secure enclave storage for private keys
- Add user safety features (block/report)

## Troubleshooting
| Issue | Tip |
|-------|-----|
| Push tokens not saving | Confirm Firebase Messaging delegate set early & APNs capability added |
| Biometric prompt not appearing | Check device settings & `biometricType` detection; simulator may not support |
| Messages show ciphertext / fail decrypt | Ensure both users published public keys; verify Firestore `publicKey` field |
| Camera / QR not working | Check `NSCameraUsageDescription` in Info.plist |
| Auth state not updating UI | Confirm `AppCoordinator` is injected via `environmentObject` |

## Contributing
1. Fork & create feature branch
2. Keep PRs focused & small
3. Add / update tests for logic changes
4. Update README / docs if behavior shifts

---
