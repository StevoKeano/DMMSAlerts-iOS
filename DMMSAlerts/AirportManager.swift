import Foundation
import CoreLocation
struct Airport {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let elevation: Double
}
class AirportManager {
    static let shared = AirportManager()
    
    private var airports: [Airport] = []
    private let queue = DispatchQueue(label: "com.dmmsalerts.airportLoader", qos: .userInitiated)
    
    init() {
        // Don't block init!
    }
    	

    func loadAirports(completion: @escaping () -> Void) {
      queue.async { [weak self] in
          guard let self = self else { return }
          
          let start = CFAbsoluteTimeGetCurrent()
          guard let path = Bundle.main.path(forResource: "Stations", ofType: "csv") else {
              print("CRITICAL: Stations.csv not found!")
              return
          }
          
          var content = ""
          do {
              // Attempt 1: UTF-8 (Standard)
              content = try String(contentsOfFile: path, encoding: .utf8)
          } catch {
              print("UTF-8 Failed. Trying Windows-1252...")
              do {
                  // Attempt 2: Windows CP1252 (Common for Excel CSVs)
                  content = try String(contentsOfFile: path, encoding: .windowsCP1252)
              } catch {
                  print("Windows-1252 Failed. Trying ASCII...")
                  do {
                      // Attempt 3: ASCII (Fallback)
                      content = try String(contentsOfFile: path, encoding: .ascii)
                  } catch {
                      print("CRITICAL: Failed to read Stations.csv with ANY encoding: \(error)")
                      return
                  }
              }
          }
          
          let rows = content.components(separatedBy: .newlines)
          
          var loadedAirports: [Airport] = []
          loadedAirports.reserveCapacity(rows.count)
          
          for row in rows.dropFirst() {
              let columns = row.components(separatedBy: ",")
              if columns.count >= 6 {
                  let id = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                  // Robust Double Parsing
                  if let lat = Double(columns[2].trimmingCharacters(in: .whitespacesAndNewlines)),
                     let lon = Double(columns[3].trimmingCharacters(in: .whitespacesAndNewlines)),
                     let elev = Double(columns[4].trimmingCharacters(in: .whitespacesAndNewlines)) {
                      
                      let site = columns[5].trimmingCharacters(in: .whitespacesAndNewlines)
                          .replacingOccurrences(of: "\"", with: "") // Clean quotes
                      
                      loadedAirports.append(Airport(id: id, name: site, latitude: lat, longitude: lon, elevation: elev))
                  }
              }
          }
          
          DispatchQueue.main.async {
              self.airports = loadedAirports
              let diff = CFAbsoluteTimeGetCurrent() - start
              print("AirportManager loaded \(self.airports.count) airports in \(String(format: "%.3f", diff))s")
              completion()
          }
      }
  }
  
    // Thread-safe search
    func findNearest(to location: CLLocation) -> (airport: Airport, distance: Double, bearing: Double)? {
        // If loading isn't done, return nil immediately
        if airports.isEmpty { return nil }
        
        var nearest: Airport?
        var minDistance: Double = .greatestFiniteMagnitude
        
        for airport in airports {
            // Optimization: Quick Haversine approx or simple distance check
            // CoreLocation distance is fast enough for <10k items usually
            let airportLoc = CLLocation(latitude: airport.latitude, longitude: airport.longitude)
            let dist = location.distance(from: airportLoc)
            
            if dist < minDistance {
                minDistance = dist
                nearest = airport
            }
        }
        
        guard let closest = nearest else { return nil }
        
        let bearing = calculateBearing(from: location.coordinate, to: CLLocationCoordinate2D(latitude: closest.latitude, longitude: closest.longitude))
        
        return (closest, minDistance / 1000.0, bearing)
    }
    
    private func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return (radiansBearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}
