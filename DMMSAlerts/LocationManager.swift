import Foundation
import CoreLocation
import UIKit
// Notification to update UI
extension Notification.Name {
    static let didUpdateLocation = Notification.Name("didUpdateLocation")
}
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    // Published data
    var currentLocation: CLLocation?
    var currentSpeed: Double = 0.0 // in knots
    var currentHeading: Double = 0.0
    var currentAltitude: Double = 0.0 // in feet
    
    var isMonitoring = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone // Update on every move
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .airborne // Critical for flight tracking
    }
    
    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startMonitoring() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        isMonitoring = true
    }
    
    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isMonitoring = false
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        
        // Convert m/s to knots (1 m/s = 1.94384 knots)
        let speedInKnots = max(0, location.speed * 1.94384)
        currentSpeed = speedInKnots
        
        // Convert meters to feet (1 m = 3.28084 ft)
        currentAltitude = location.altitude * 3.28084
        
        // Notify UI and Logic
        NotificationCenter.default.post(name: .didUpdateLocation, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
    }
}
