import Foundation
import CoreLocation
struct MetarData: Codable {
    let icaoId: String?
    let wdir: Int?
    let wspd: Int?
    let wgst: Int?
    let lat: Double?
    let lon: Double?
}
class WeatherManager {
    static let shared = WeatherManager()
    private let session = URLSession.shared
    private var lastFetchTime: Date?
    private var cachedMetar: MetarData?
    
    // MARK: - Public API
    
    func fetchMetar(for airportID: String, completion: @escaping (MetarData?) -> Void) {
        // Ensure ID is clean
        let cleanID = airportID.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanID.isEmpty { completion(nil); return }
        
        let urlString = "https://aviationweather.gov/api/data/metar?ids=\(cleanID)&format=json"
        performRequest(urlString: urlString, context: "ID: \(cleanID)", completion: completion)
    }
    

    
    func fetchMetarExpanding(location: CLLocation, completion: @escaping (MetarData?) -> Void) {
           // Start small (0.25 deg ~ 17 miles) to get local weather first
           attemptBoxSearch(location: location, delta: 0.25, completion: completion)
       }
       
    private func attemptBoxSearch(location: CLLocation, delta: Double, completion: @escaping (MetarData?) -> Void) {
           if delta > 2.0 {
               print("Expanding Search gave up at delta \(delta)")
               completion(nil)
               return
           }
           
           let lat = location.coordinate.latitude
           let lon = location.coordinate.longitude
           
           // MAUI Logic: Increment 0.05
           let nextDelta = delta + 0.05
           
           // Format BBox (US Locale to force dots)
           let usLocale = Locale(identifier: "en_US")
           let latMin = String(format: "%.4f", locale: usLocale, lat - delta)
           let latMax = String(format: "%.4f", locale: usLocale, lat + delta)
           let lonMin = String(format: "%.4f", locale: usLocale, lon - delta)
           let lonMax = String(format: "%.4f", locale: usLocale, lon + delta)
           
           // MAUI ORDER: Lat, Lon, Lat, Lon
           // Standard spec says Lon,Lat, but we must obey the Working Code.
           let urlString = "https://aviationweather.gov/api/data/metar?bbox=\(latMin),\(lonMin),\(latMax),\(lonMax)&format=json"
           
           // print("DEBUG: Trying BBox: \(urlString)") // Uncomment to verify
           
           guard let url = URL(string: urlString) else { completion(nil); return }
           var request = URLRequest(url: url)
           request.setValue("DMMSAlerts/1.0", forHTTPHeaderField: "User-Agent")
           
           session.dataTask(with: request) { [weak self] data, response, error in
               if let data = data, let self = self {
                   let decoder = JSONDecoder()
                   if let list = try? decoder.decode([MetarData].self, from: data) {
                       // Filter and Sort by Distance
                       let validList = list.filter { $0.wspd != nil && $0.wdir != nil }
                       if let closest = validList.min(by: { a, b in
                           let locA = CLLocation(latitude: a.lat ?? 0, longitude: a.lon ?? 0)
                           let locB = CLLocation(latitude: b.lat ?? 0, longitude: b.lon ?? 0)
                           return location.distance(from: locA) < location.distance(from: locB)
                       }) {
                           print("Found METAR at delta \(String(format: "%.2f", delta)): \(closest.icaoId ?? "?")")
                           self.cache(closest)
                           completion(closest)
                           return
                       }
                   }
               }
               
               // RECURSE (Increment by 0.05 like MAUI)
               self?.attemptBoxSearch(location: location, delta: nextDelta, completion: completion)
               
           }.resume()
       }   
    func calculateWindComponent(heading: Double, metar: MetarData) -> Double {
        guard let windDir = metar.wdir, let windSpd = metar.wspd else { return 0.0 }
        var effectiveWind = Double(windSpd)
        if let gust = metar.wgst, gust > windSpd { effectiveWind += Double(gust - windSpd) / 2.0 }
        let angleDiff = (Double(windDir) - heading) * .pi / 180.0
        return effectiveWind * cos(angleDiff)
    }
    
    // MARK: - Private Helpers
    
    private func performRequest(urlString: String, context: String, sortLocation: CLLocation? = nil, completion: @escaping (MetarData?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("URL Error: \(urlString)")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("DMMSAlerts/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        session.dataTask(with: request) { [weak self] data, response, error in
            // 1. Check Network Error
            if let error = error {
                print("Network Error (\(context)): \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // 2. Check HTTP Status
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("HTTP Error (\(context)): Code \(httpResponse.statusCode)")
                    completion(nil)
                    return
                }
            }
            
            // 3. Check Data
            guard let data = data, !data.isEmpty else {
                print("Empty Data (\(context)): Server returned 0 bytes.")
                completion(nil)
                return
            }
            
            // 4. Decode
            let decoder = JSONDecoder()
            
            // Try Array
            if let list = try? decoder.decode([MetarData].self, from: data) {
                let validList = list.filter { $0.wspd != nil && $0.wdir != nil }
                
                if let location = sortLocation {
                    // Sort by distance
                    if let closest = validList.min(by: { a, b in
                        let locA = CLLocation(latitude: a.lat ?? 0, longitude: a.lon ?? 0)
                        let locB = CLLocation(latitude: b.lat ?? 0, longitude: b.lon ?? 0)
                        return location.distance(from: locA) < location.distance(from: locB)
                    }) {
                        self?.cache(closest)
                        completion(closest)
                        return
                    }
                } else if let first = validList.first {
                    self?.cache(first)
                    completion(first)
                    return
                }
            }
            
            // Try Single Object
            if let single = try? decoder.decode(MetarData.self, from: data) {
                if single.wspd != nil {
                    self?.cache(single)
                    completion(single)
                    return
                }
            }
            
            // 5. Debug Failure
            let raw = String(data: data, encoding: .utf8) ?? "Unreadable Data"
            if raw == "[]" {
                print("API Empty (\(context)): No stations found.")
            } else if raw.contains("error") {
                print("API Error (\(context)): \(raw)")
            } else {
                print("Parse Fail (\(context)). Bytes: \(data.count). Content: \(raw.prefix(100))...")
            }
            completion(nil)
            
        }.resume()
    }
    
    private func cache(_ metar: MetarData) {
        self.cachedMetar = metar
        self.lastFetchTime = Date()
    }
}
	
