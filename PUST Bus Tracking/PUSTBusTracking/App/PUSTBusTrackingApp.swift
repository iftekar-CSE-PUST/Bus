import SwiftUI
import UserNotifications
import WebKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Register delegate with User Notification Center
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Request notification authorization and register for Apple Push Notification service (APNs)
        NotificationManager.shared.requestNotificationPermissions(application: application)
        
        return true
    }
    
    // Successfully received Apple Push Token from APNs
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device APNs Push Token: \(token)")
        
        NotificationManager.shared.apnsToken = token
        
        // Pass token to JavaScript webview
        DispatchQueue.main.async {
            let js = """
            window.__devicePushToken = '\(token)';
            if (typeof window.__onDevicePushToken === 'function') {
                window.__onDevicePushToken('\(token)');
            }
            """
            NotificationManager.shared.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    // Failed to register for remote notifications
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for APNs remote notifications: \(error.localizedDescription)")
    }
    
    // Handle background remote notification payload when app is closed / background
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if let bus = userInfo["bus"] as? Int, bus > 0 {
            DispatchQueue.main.async {
                let js = "if (typeof openChat === 'function') { openChat(\(bus)); }"
                NotificationManager.shared.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
        }
        completionHandler(.newData)
    }
}

@main
struct PUSTBusTrackingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
