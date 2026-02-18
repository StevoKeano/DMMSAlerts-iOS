import Foundation
import CoreLocation
struct MetarData: Codable {
    let icaoId: String?
    let wdir: Int? // Wind Direction
    let wspd: Int? // Wind Speed
    let wgst: Int? // Gust
    let lat: Double?
    let lon: Double?
}
class WeatherManager {
    static let shared = WeatherManager()
    private let session = URLSession.shared
    
    // Caching
    private var lastFetchTime: Date?
    private var cachedMetar: MetarData?
    private let fetchInterval: TimeInterval = 300 // 5 mins
    
    // MARK: - Public API
    
    func fetchMetar(for airportID: String, completion: @escaping (MetarData?) -> Void) {
        if isCacheValid(for: airportID) { completion(cachedMetar); return }
        
        let urlString = "https://aviationweather.gov/api/data/metar?ids=\(airportID)&format=json"
        performRequest(urlString: urlString, completion: completion)
    }
    
    func fetchMetarByBox(location: CLLocation, completion: @escaping (MetarData?) -> Void) {
        // Expand to 1.0 degree (~69 miles) to guarantee a hit
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let delta = 1.0
        
        // Standard BBOX order: minLon, minLat, maxLon, maxLat
        let urlString = "https://aviationweather.gov/api/data/metar?bbox=\(lon-delta),\(lat-delta),\(lon+delta),\(lat+delta)&format=json"
        
        print("DEBUG: Fetching BBox URL: \(urlString)")
        
        performRequest(urlString: urlString) { [weak self] metar in
            if let metar = metar, let id = metar.icaoId {
                print("BBox found valid station: \(id) (Wind: \(metar.wspd ?? 0)kts)")
                self?.cache(metar)
            }
            completion(metar)
        }
    }
    
    func calculateWindComponent(heading: Double, metar: MetarData) -> Double {
        guard let windDir = metar.wdir, let windSpd = metar.wspd else { return 0.0 }
        
        var effectiveWind = Double(windSpd)
        if let gust = metar.wgst, gust > windSpd {
            effectiveWind += Double(gust - windSpd) / 2.0
        }
        
        let angleDiff = (Double(windDir) - heading) * .pi / 180.0
        return effectiveWind * cos(angleDiff)
    }
    
    // MARK: - Private Helpers
    
    private func performRequest(urlString: String, completion: @escaping (MetarData?) -> Void) {
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Weather Network Error: \(error?.localizedDescription ?? "Unknown")")
                completion(nil)
                return
            }
            
            let decoder = JSONDecoder()
            
            // Attempt 1: Decode Array (Standard for BBox)
            if let list = try? decoder.decode([MetarData].self, from: data) {
                // 10x LOGIC: Don't just take the first one. Find the first one with VALID WIND.
                if let validStation = list.first(where: { $0.wspd != nil && $0.wdir != nil }) {
                    self?.cache(validStation)
                    completion(validStation)
                    return
                }
            }
            
            // Attempt 2: Decode Single Object (Standard for single ID)
            if let single = try? decoder.decode(MetarData.self, from: data) {
                if single.wspd != nil {
                    self?.cache(single)
                    completion(single)
                    return
                }
            }
            
            // Debugging: If we failed, what did we get?
            let rawString = String(data: data, encoding: .utf8) ?? "Unreadable"
            if rawString == "[]" {
                print("API returned empty list (No stations in box).")
            } else {
                print("Parse Failed. Raw Response: \(rawString.prefix(100))...")
            }
            completion(nil)
            
        }.resume()
    }
    
    private func isCacheValid(for id: String) -> Bool {
        if let last = lastFetchTime, let cached = cachedMetar,
           last.timeIntervalSinceNow > -fetchInterval, cached.icaoId == id {
            print("Using cached METAR for \(id)")
            return true
        }
        return false
    }
    
    private func cache(_ metar: MetarData) {
        self.cachedMetar = metar
        self.lastFetchTime = Date()
    }
}
