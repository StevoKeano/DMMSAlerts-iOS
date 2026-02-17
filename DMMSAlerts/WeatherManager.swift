//
//  WeatherManager.swift
//  DMMSAlerts
//
//  Created by Stephen Kean on 2/17/26.
//

import Foundation
import CoreLocation
// MARK: - Data Models
struct MetarData: Codable {
    let icaoId: String?
    let wdir: Int? // Wind Direction (Degrees)
    let wspd: Int? // Wind Speed (Knots)
    let wgst: Int? // Wind Gust (Knots)
    let receiptTime: String?
}
class WeatherManager {
    static let shared = WeatherManager()
    
    private let session = URLSession.shared
    private var lastFetchTime: Date?
    private var cachedMetar: MetarData?
    
    // Config
    private let fetchInterval: TimeInterval = 300 // 5 minutes (300s)
    
    // MARK: - Fetch Logic
    func fetchMetar(for airportID: String, completion: @escaping (MetarData?) -> Void) {
        // Cache Check: Don't spam the API
        if let last = lastFetchTime, let cached = cachedMetar,
           last.timeIntervalSinceNow > -fetchInterval, cached.icaoId == airportID {
            print("Using cached METAR for \(airportID)")
            completion(cached)
            return
        }
        
        // Build URL (Official AviationWeather.gov API)
        let urlString = "https://aviationweather.gov/api/data/metar?ids=\(airportID)&format=json"
        guard let url = URL(string: urlString) else { return }
        
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("METAR Fetch Error: \(error?.localizedDescription ?? "Unknown")")
                completion(nil)
                return
            }
            
            do {
                // Parse JSON Array (API returns [MetarData])
                let metars = try JSONDecoder().decode([MetarData].self, from: data)
                if let validMetar = metars.first {
                    self?.cachedMetar = validMetar
                    self?.lastFetchTime = Date()
                    print("Fetched METAR for \(airportID): Wind \(validMetar.wdir ?? 0)° at \(validMetar.wspd ?? 0)kts")
                    completion(validMetar)
                } else {
                    completion(nil)
                }
            } catch {
                print("METAR Parse Error: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    // MARK: - Calculation Logic
    func calculateWindComponent(heading: Double, metar: MetarData) -> Double {
        guard let windDir = metar.wdir, let windSpd = metar.wspd else { return 0.0 }
        
        // Calculate Gust Factor (if gust > speed, add half difference)
        var effectiveWindSpeed = Double(windSpd)
        if let gust = metar.wgst, gust > windSpd {
            effectiveWindSpeed += Double(gust - windSpd) / 2.0
        }
        
        // Calculate Angle Difference
        // Headwind = Cos(Angle) * Speed
        // Tailwind = Negative Result
        let angleDiff = (Double(windDir) - heading) * .pi / 180.0
        let component = effectiveWindSpeed * cos(angleDiff)
        
        return component
    }
}
	
