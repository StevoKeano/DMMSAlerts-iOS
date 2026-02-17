//
//  AirportManager.swift
//  DMMSAlerts
//
//  Created by Stephen Kean on 2/17/26.
//

import Foundation
import CoreLocation
struct Airport {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let elevation: Double // in feet
}
class AirportManager {
    static let shared = AirportManager()
    private var airports: [Airport] = []
    
    init() {
        loadAirports()
    }
    
    private func loadAirports() {
        guard let path = Bundle.main.path(forResource: "Stations", ofType: "csv") else {
            print("Stations.csv not found in bundle!")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path)
            let rows = content.components(separatedBy: "\n")
            
            for row in rows.dropFirst() { // Skip header
                let columns = row.components(separatedBy: ",")
                if columns.count >= 6 {
                    // Adjust indices based on your specific CSV structure!
                    // Assuming: ID, Name, Lat, Lon, Elev, ...
                    let id = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let lat = Double(columns[2]) ?? 0.0
                    let lon = Double(columns[3]) ?? 0.0
                    let elev = Double(columns[4]) ?? 0.0
                    let name = columns[5].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if lat != 0.0 && lon != 0.0 {
                        let airport = Airport(id: id, name: name, latitude: lat, longitude: lon, elevation: elev)
                        airports.append(airport)
                    }
                }
            }
            print("Loaded \(airports.count) airports.")
        } catch {
            print("Failed to load airports: \(error)")
        }
    }
    
    func findNearest(to location: CLLocation) -> (airport: Airport, distance: Double, bearing: Double)? {
        guard !airports.isEmpty else { return nil }
        
        var nearest: Airport?
        var minDistance: Double = .greatestFiniteMagnitude
        
        for airport in airports {
            let airportLoc = CLLocation(latitude: airport.latitude, longitude: airport.longitude)
            let distance = location.distance(from: airportLoc)
            
            if distance < minDistance {
                minDistance = distance
                nearest = airport
            }
        }
        
        guard let closest = nearest else { return nil }
        
        let bearing = calculateBearing(from: location.coordinate, to: CLLocationCoordinate2D(latitude: closest.latitude, longitude: closest.longitude))
        
        return (closest, minDistance, bearing)
    }
    
    private func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude.degreesToRadians
        let lon1 = start.longitude.degreesToRadians
        let lat2 = end.latitude.degreesToRadians
        let lon2 = end.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        // Convert to degrees (0-360)
        return (radiansBearing.radiansToDegrees + 360).truncatingRemainder(dividingBy: 360)
    }
}
extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}
