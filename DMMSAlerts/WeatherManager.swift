import Foundation
import CoreLocation
struct MetarData: Codable {
    let icaoId: String?
    let wdir: Int? // Wind Direction
    let wspd: Int? // Wind Speed
    let wgst: Int? // Gust
    let lat: Double? // For distance calculation
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
    
    // 1. Try ID
    func fetchMetar(for airportID: String, completion: @escaping (MetarData?) -> Void) {
        if isCacheValid(for: airportID) { completion(cachedMetar); return }
        
        let urlString = "https://aviationweather.gov/api/data/metar?ids=\(airportID)&format=json"
        performRequest(urlString: urlString, completion: completion)
    }
    
    // 2. Try Bounding Box (Fallback)
    func fetchMetarByBox(location: CLLocation, completion: @escaping (MetarData?) -> Void) {
        // Create a ~0.5 degree box (approx 30 miles) around the location
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let delta = 0.5
        // bbox=minLat,minLon,maxLat,maxLon
        let urlString = "https://aviationweather.gov/api/data/metar?bbox=\(lat-delta),\(lon-delta),\(lat+delta),\(lon+delta)&format=json"
        
        performRequest(urlString: urlString) { [weak self] metar in
            // If BBox returns a station, cache it so we don't spam the API
            if let metar = metar, let id = metar.icaoId {
                print("BBox found nearby station: \(id)")
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
                print("Weather Fetch Error: \(error?.localizedDescription ?? "Unknown")")
                completion(nil)
                return
            }
            
            let decoder = JSONDecoder()
            
            // Attempt 1: Decode Array
            if let list = try? decoder.decode([MetarData].self, from: data), let first = list.first {
                self?.cache(first)
                completion(first)
                return
            }
            
            // Attempt 2: Decode Single Object
            if let single = try? decoder.decode(MetarData.self, from: data) {
                self?.cache(single)
                completion(single)
                return
            }
            
            // Failure
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
	
