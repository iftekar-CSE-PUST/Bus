import SwiftUI
import WebKit
import CoreLocation
import UserNotifications

struct WebViewContainer: UIViewRepresentable {
    @Binding var isLoaded: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Persistent storage for user sessions and preferences
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // Add native bridge message handlers
        configuration.userContentController.add(context.coordinator, name: "requestNativeLocation")
        configuration.userContentController.add(context.coordinator, name: "sendLocalNotification")
        configuration.userContentController.add(context.coordinator, name: "requestNotificationPermission")
        
        // Inject script to prevent viewport zooming on the app UI while preserving map gestures
        let zoomDisableScript = WKUserScript(
            source: """
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.getElementsByTagName('head')[0].appendChild(meta);
            }
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
            
            document.addEventListener('gesturestart', function(e) {
                if (e.target && (e.target.closest('#map') || e.target.closest('.mapwrap') || e.target.closest('.mapscreen') || e.target.closest('.leaflet-container') || e.target.closest('canvas'))) {
                    return;
                }
                e.preventDefault();
            }, { passive: false });
            
            document.addEventListener('gesturechange', function(e) {
                if (e.target && (e.target.closest('#map') || e.target.closest('.mapwrap') || e.target.closest('.mapscreen') || e.target.closest('.leaflet-container') || e.target.closest('canvas'))) {
                    return;
                }
                e.preventDefault();
            }, { passive: false });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(zoomDisableScript)
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        
        LocationManager.shared.webView = webView
        NotificationManager.shared.webView = webView
        
        // Load the local HTML tracking interface
        loadLocalHTML(in: webView)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Reserved for dynamic updates
    }
    
    private func loadLocalHTML(in webView: WKWebView) {
        let bundleURL = Bundle.main.bundleURL
        // Priority 1: Check Resources subdirectory
        if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: bundleURL)
            return
        }
        
        // Priority 2: Check main bundle root
        if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: bundleURL)
            return
        }
        
        // Priority 3: Fallback any HTML in bundle
        if let anyHtml = Bundle.main.urls(forResourcesWithExtension: "html", subdirectory: nil)?.first {
            webView.loadFileURL(anyHtml, allowingReadAccessTo: bundleURL)
            return
        }
        
        print("Error: index.html could not be located in application bundle.")
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // MARK: - WKScriptMessageHandler
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "requestNativeLocation" {
                if let dict = message.body as? [String: Any], let active = dict["active"] as? Bool {
                    if active {
                        LocationManager.shared.requestPermission()
                    } else {
                        LocationManager.shared.stopTracking()
                    }
                } else {
                    LocationManager.shared.requestPermission()
                }
            } else if message.name == "requestNotificationPermission" {
                NotificationManager.shared.requestNotificationPermissions()
            } else if message.name == "sendLocalNotification" {
                if let dict = message.body as? [String: Any],
                   let title = dict["title"] as? String,
                   let body = dict["body"] as? String {
                    let subtitle = dict["subtitle"] as? String
                    let bus = dict["bus"] as? Int ?? 0
                    NotificationManager.shared.postNotification(title: title, subtitle: subtitle, body: body, bus: bus)
                }
            }
        }
        
        // MARK: - WKNavigationDelegate
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoaded = true
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WKWebView navigation error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.parent.isLoaded = true
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WKWebView provisional navigation error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.parent.isLoaded = true
            }
        }
        
        // MARK: - WKUIDelegate (Native iOS JavaScript Dialogs)
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                completionHandler()
                return
            }
            
            let alert = UIAlertController(title: "PUST Bus Tracking", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ঠিক আছে", style: .default) { _ in
                completionHandler()
            })
            rootVC.present(alert, animated: true)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                completionHandler(false)
                return
            }
            
            let alert = UIAlertController(title: "নিশ্চিত করুন", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "না (বাতিল)", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "হ্যাঁ", style: .default) { _ in
                completionHandler(true)
            })
            rootVC.present(alert, animated: true)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                completionHandler(nil)
                return
            }
            
            let alert = UIAlertController(title: "তথ্য দিন", message: prompt, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = defaultText
            }
            alert.addAction(UIAlertAction(title: "বাতিল", style: .cancel) { _ in
                completionHandler(nil)
            })
            alert.addAction(UIAlertAction(title: "ঠিক আছে", style: .default) { _ in
                let text = alert.textFields?.first?.text
                completionHandler(text)
            })
            rootVC.present(alert, animated: true)
        }
        
        // Handle iOS 15+ permissions for orientation and media capture
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
        
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
    }
}
