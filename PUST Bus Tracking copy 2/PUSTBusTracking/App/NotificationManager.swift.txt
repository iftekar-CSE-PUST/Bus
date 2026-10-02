import Foundation
import UserNotifications
import WebKit
import UIKit

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    weak var webView: WKWebView?
    var apnsToken: String?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        
        // Ensure no badge number is displayed on the app icon using modern API
        clearBadgeCount()
    }
    
    // Modern badge reset without any deprecated UIApplication APIs
    func clearBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }
    
    // Prompt real iOS System Notification permission dialog (Alert & Sound only, No Badge)
    func requestNotificationPermissions(application: UIApplication? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            print("System Notification Permission Granted: \(granted)")
            if granted {
                DispatchQueue.main.async {
                    if let app = application {
                        app.registerForRemoteNotifications()
                    } else {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            
            // Notify JavaScript webview about permission state
            DispatchQueue.main.async {
                let js = "if (typeof window.__onNotificationPermission === 'function') { window.__onNotificationPermission(\(granted)); }"
                self.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }
    
    // Post Real iOS System Notification (Alert Banner & Sound only - No badge symbol)
    func postNotification(title: String, subtitle: String? = nil, body: String, bus: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let sub = subtitle, !sub.isEmpty {
            content.subtitle = sub
        }
        content.body = body
        content.sound = UNNotificationSound.default
        // No badge count on app icon
        content.userInfo = ["bus": bus]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pust_chat_\(bus)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error presenting system notification: \(error.localizedDescription)")
            } else {
                print("Successfully presented system notification: \(title) -> \(body)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    // Present banner, sound, and lock-screen notification (No badge symbol)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .list])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    // When rider taps on the system notification banner / lock screen, open that bus's chat
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Clear any icon badge if present
        clearBadgeCount()
        
        let userInfo = response.notification.request.content.userInfo
        if let bus = userInfo["bus"] as? Int, bus > 0 {
            DispatchQueue.main.async {
                let js = "if (typeof openChat === 'function') { openChat(\(bus)); }"
                self.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
        }
        completionHandler()
    }
}
