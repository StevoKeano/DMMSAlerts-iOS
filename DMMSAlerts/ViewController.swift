import UIKit
import CoreLocation
import CoreMotion
import AVFoundation
class ViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var dmmsValueLabel: UILabel!
    @IBOutlet weak var airportLabel: UILabel! // New Outlet for Airport Info!
    @IBOutlet weak var dmmsPicker: UIPickerView!
    @IBOutlet weak var warningImage: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    
    // MARK: - Core Managers
    private let locationManager = LocationManager.shared
    private let motionManager = CMMotionManager()
    private let synthesizer = AVSpeechSynthesizer()
    private let defaults = UserDefaults.standard
    
    // MARK: - State Variables
    private var dmmsThreshold: Double = 70.0
    private var gForce: Double = 1.0
    private var adjustedStallSpeed: Double = 0.0
    private var isAlertActive = false
    private var alertTimer: Timer?
    private var isPaused = true
    private var currentMetar: MetarData?
    private var windComponent: Double = 0.0
    private var lastWeatherFetchTime: Date?
    // Airport Logic State
    private var lastStationID: String = "N/A"
    private var landingModeActive = false
    private let airportProximityKm = 0.9 // 0.9km threshold for "landing" logic
    private let landingAltitudeBuffer = 10.0 // 10ft above airport elev
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
           super.viewDidLoad()
           setupUI()
           setupPicker()
           setupMotionManager()
           
           // Load airports in background
           AirportManager.shared.loadAirports { [weak self] in
               self?.airportLabel.text = "Airports loaded!"
           }
           
           NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .didUpdateLocation, object: nil)
           
           if let savedDMMS = defaults.value(forKey: "DMMSValue") as? Double {
               dmmsThreshold = savedDMMS
           }
           updateDMMSLabel()
       }
    private func setupUI() {
        view.backgroundColor = UIColor.systemBlue
        warningImage.isHidden = true
        warningImage.image = UIImage(systemName: "exclamationmark.triangle.fill")
        statusLabel.text = "PAUSED"
        startButton.setTitle("Start Monitoring", for: .normal)
        startButton.backgroundColor = .systemGreen
        startButton.layer.cornerRadius = 10
        airportLabel.text = "Searching for airports..."
    }
    
    private func setupPicker() {
        dmmsPicker.dataSource = self
        dmmsPicker.delegate = self
        let defaultRow = Int(dmmsThreshold) - 1
        if defaultRow >= 0 && defaultRow < 270 {
            dmmsPicker.selectRow(defaultRow, inComponent: 0, animated: false)
        }
    }
    private func setupMotionManager() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data else { return }
                let totalG = sqrt(pow(data.acceleration.x, 2) + pow(data.acceleration.y, 2) + pow(data.acceleration.z, 2))
                self.gForce = totalG
                self.calculateStallSpeed()
            }
        } else {
            print("Accelerometer unavailable (Simulator). Defaulting to 1.0 G.")
            self.gForce = 1.0
            self.calculateStallSpeed()
        }
    }
    
    // MARK: - Main Loop (Triggered by Location Updates)
    @objc private func updateUI() {
       guard !isPaused, let location = locationManager.currentLocation else { return }
       
       let groundSpeed = locationManager.currentSpeed
       let alt = locationManager.currentAltitude
       let head = locationManager.currentHeading
       
       // --- NEW: Calculate Effective Airspeed (IAS) ---
       // IAS = GroundSpeed + HeadwindComponent
       // (Headwind is positive, Tailwind is negative)
       let effectiveAirspeed = max(0, groundSpeed + windComponent)
       
       // Update Labels
       if windComponent != 0 {
           speedLabel.text = String(format: "IAS: %.0f KTS", effectiveAirspeed)
           statusLabel.text = "METAR ACTIVE (\(currentMetar?.icaoId ?? "?"))"
           statusLabel.textColor = .systemGreen
       } else {
           speedLabel.text = String(format: "GPS: %.0f KTS", groundSpeed)
       }
       
       altitudeLabel.text = String(format: "%.0f FT", alt)
       headingLabel.text = String(format: "HDG: %.0f°", head)
       
       // Check Logic
       checkNearestAirport(location: location, altitudeFt: alt)
       checkAlerts(currentSpeed: effectiveAirspeed) // Use IAS for safety!
   }
   
    
    
    private func checkNearestAirport(location: CLLocation, altitudeFt: Double) {
        guard let result = AirportManager.shared.findNearest(to: location) else { return }
        
        let airport = result.airport
        let distKm = result.distance
        let distMiles = distKm * 0.621371
        
        airportLabel.text = String(format: "Closest: %@, %.0f mi %.0f° %.0f ft",
                                   airport.id, distMiles, result.bearing, airport.elevation)
        
        // Landing Logic
        let altitudeDiff = altitudeFt - airport.elevation
        if distKm <= airportProximityKm && altitudeDiff < landingAltitudeBuffer {
            landingModeActive = true
            statusLabel.text = "LANDING MODE"
            statusLabel.textColor = .systemYellow
        } else {
            landingModeActive = false
            statusLabel.text = "MONITORING"
            statusLabel.textColor = .white
        }
        
        // TTS Logic
        if airport.id != lastStationID {
            lastStationID = airport.id
            let speechText = String(format: "%@, %.0f miles", airport.id, distMiles)
            speak(text: speechText)
            
            // Force fetch immediately if airport changes
            performWeatherFetch(for: airport, location: location)
        } else {
            // Airport hasn't changed. Only fetch if 5 minutes have passed (Throttle)
            let timeSince = lastWeatherFetchTime?.timeIntervalSinceNow ?? -999
            if timeSince < -3 { // -300 seconds = 5 minutes ago
                performWeatherFetch(for: airport, location: location)
            }
        }
    }
    
    private func performWeatherFetch(for airport: Airport, location: CLLocation) {
        lastWeatherFetchTime = Date() // Reset Timer
        
        WeatherManager.shared.fetchMetar(for: airport.id) { [weak self] metar in
            if let metar = metar {
                self?.updateMetarUI(metar)
            } else {
                print("No METAR for \(airport.id). Searching BBox...")
                WeatherManager.shared.fetchMetarByBox(location: location) { boxMetar in
                    if let boxMetar = boxMetar {
                        self?.updateMetarUI(boxMetar)
                    }
                }
            }
        }
    }

    private func updateMetarUI(_ metar: MetarData) {
        DispatchQueue.main.async {
            self.currentMetar = metar
            let heading = self.locationManager.currentHeading
            self.windComponent = WeatherManager.shared.calculateWindComponent(heading: heading, metar: metar)
            
            self.statusLabel.text = "METAR ACTIVE (\(metar.icaoId ?? "?"))"
            self.statusLabel.textColor = .systemGreen
        }
    }
    private func calculateStallSpeed() {
        let loadFactor = max(0.1, abs(gForce))
        adjustedStallSpeed = dmmsThreshold * sqrt(loadFactor)
    }
    
    private func checkAlerts(currentSpeed: Double) {
        // Suppress alerts if in Landing Mode
        if landingModeActive {
            if isAlertActive { stopAlert() }
            return
        }
        
        // Trigger Logic
        if currentSpeed < adjustedStallSpeed {
            if !isAlertActive { startAlert() }
        } else {
            if isAlertActive { stopAlert() }
        }
    }
    
    private func startAlert() {
        guard !isAlertActive else { return }
        isAlertActive = true
        warningImage.isHidden = false
        view.backgroundColor = .systemRed
        
        let text = "SPEED CHECK! STALL WARNING!"
        speak(text: text)
        
        alertTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.speak(text: text)
            // Flash UI
            UIView.animate(withDuration: 0.5, animations: {
                self?.view.backgroundColor = .systemOrange
            }) { _ in
                UIView.animate(withDuration: 0.5) {
                    self?.view.backgroundColor = .systemRed
                }
            }
        }
    }
    
    private func stopAlert() {
        isAlertActive = false
        warningImage.isHidden = true
        view.backgroundColor = .systemBlue
        alertTimer?.invalidate()
        alertTimer = nil
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // Helper for TTS
    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        // Simulator Fallback Logic
        let englishVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.starts(with: "en") })
        let anyVoice = AVSpeechSynthesisVoice.speechVoices().first
        utterance.voice = englishVoice ?? anyVoice
        
        do { try AVAudioSession.sharedInstance().setActive(true) } catch {}
        synthesizer.speak(utterance)
    }
    
    // MARK: - Actions
    @IBAction func startButtonTapped(_ sender: UIButton) {
        isPaused.toggle()
        if isPaused {
            locationManager.stopMonitoring()
            statusLabel.text = "PAUSED"
            startButton.setTitle("Resume", for: .normal)
            startButton.backgroundColor = .systemGray
            stopAlert()
        } else {
            locationManager.startMonitoring()
            statusLabel.text = "MONITORING"
            startButton.setTitle("Pause", for: .normal)
            startButton.backgroundColor = .systemRed
        }
    }
    
    private func updateDMMSLabel() {
        dmmsValueLabel.text = "DMMS: \(Int(dmmsThreshold)) KTS"
    }
}
// Picker Delegate
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return 270 }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { return "\(row + 1) KTS" }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        dmmsThreshold = Double(row + 1)
        defaults.set(dmmsThreshold, forKey: "DMMSValue")
        updateDMMSLabel()
        calculateStallSpeed()
        checkAlerts(currentSpeed: locationManager.currentSpeed) // Instant update
    }
}
