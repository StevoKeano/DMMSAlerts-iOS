import Foundation
import CoreLocation
import UIKit

extension Notification.Name {
    static let didUpdateLocation = Notification.Name("didUpdateLocation")
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastTimestamp: Date?
    
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
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startMonitoring() {
        if AppConfig.groundMode {
            locationManager.activityType = .other
        } else {
            locationManager.activityType = .airborne
        }
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
        currentAltitude = location.altitude * 3.28084 // meters to feet
        
        if AppConfig.groundMode {
            // Ground mode: calculate speed from position deltas
            if let lastLoc = lastLocation, let lastTime = lastTimestamp {
                let distance = location.distance(from: lastLoc) // meters
                let timeInterval = location.timestamp.timeIntervalSince(lastTime)
                if timeInterval > 0 {
                    let speedMps = distance / timeInterval
                    currentSpeed = max(0, speedMps * 1.94384) // m/s to knots
                }
            }
            lastLocation = location
            lastTimestamp = location.timestamp
        } else {
            // Aviation mode: use GPS speed directly
            let speedInKnots = max(0, location.speed * 1.94384)
            currentSpeed = speedInKnots
        }
        
        NotificationCenter.default.post(name: .didUpdateLocation, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
    }
}
