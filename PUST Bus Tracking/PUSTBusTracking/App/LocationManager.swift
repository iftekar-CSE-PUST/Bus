import Foundation
import CoreLocation
import Combine
import WebKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    weak var webView: WKWebView?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5.0
        self.authorizationStatus = manager.authorizationStatus
    }
    
    // Explicitly requested on demand when user taps "Start Sharing"
    func requestPermission() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            startTracking()
        }
    }
    
    func startTracking() {
        // Enable background location updates so sharing continues when minimized
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingLocation()
    }
    
    func stopTracking() {
        manager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startTracking()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.lastLocation = location
            let lat = location.coordinate.latitude
            let lng = location.coordinate.longitude
            let acc = location.horizontalAccuracy
            let speed = max(0, location.speed)
            let heading = max(0, location.course)
            let js = """
            window.__lastNativeLocationTime = Date.now();
            window.__lastNativeLocation = {
                coords: {
                    latitude: \(lat),
                    longitude: \(lng),
                    accuracy: \(acc),
                    speed: \(speed),
                    heading: \(heading)
                },
                timestamp: Date.now()
            };
            if (typeof window.__onNativeLocation === 'function') {
                window.__onNativeLocation(\(lat), \(lng), \(acc), \(speed), \(heading));
            }
            """
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
