//
//  ChatifyApp.swift
//  Chatify
//
//  Created by Pavithra Chamod on 2025-08-20.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        configurePushNotifications(application: application)
        return true
    }
    private func configurePushNotifications(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async { application.registerForRemoteNotifications() }
            }
        }
        Messaging.messaging().delegate = self
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        // Persist token & history for current user
        if let uid = Auth.auth().currentUser?.uid {
            let userRef = Firestore.firestore().collection("user").document(uid)
            userRef.setData([
                "fcmToken": token,
                "fcmTokens": FieldValue.arrayUnion([token]),
                "fcmTokenUpdatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        DispatchQueue.main.async {
            AppCoordinator.shared.handleRemoteNotification(userInfo: userInfo)
        }
        completionHandler()
    }
    
    private func postLocalNotificationIfNeeded(from userInfo: [AnyHashable: Any]) {
        if userInfo["aps"] != nil { return }
        guard let type = userInfo["type"] as? String else { return }
        let content = UNMutableNotificationContent()
        switch type {
        case "message":
            content.title = (userInfo["fromName"] as? String).map { "New message from \($0)" } ?? "New Message"
            content.body = (userInfo["preview"] as? String) ?? "You received a new message."
            content.sound = .default
            content.userInfo = userInfo
        case "friend_request":
            content.title = "New Friend Request"
            content.body = (userInfo["fromName"] as? String).map { "\($0) sent you a friend request" } ?? "You received a friend request."
            content.sound = .default
            content.userInfo = userInfo
        default:
            return
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppCoordinator.shared.handleRemoteNotification(userInfo: userInfo)
        postLocalNotificationIfNeeded(from: userInfo)
        completionHandler(.noData)
    }
}

@main
struct ChatifyApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var coordinator = AppCoordinator.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(coordinator)
                .onAppear {
                    coordinator.refreshAuthState()
                }
        }
    }
}
