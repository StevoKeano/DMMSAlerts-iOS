import UIKit
import CoreLocation
import CoreMotion
import AVFoundation
// MARK: - 10x Configuration Manager
struct AppConfig {
    static let defaults = UserDefaults.standard
    
    // Keys
    private static let kDMMS = "DMMSValue"
    private static let kMsgFreq = "MessageFrequency"
    private static let kWeatherInterval = "WeatherFetchInterval"
    private static let kLandingBuffer = "LandingAltitudeBuffer"
    private static let kLandingDist = "LandingDistanceKm"
    private static let kAutoStart = "AutoActivate"
    private static let kAlertMessage = "AlertMessage"
    private static let kAppTitle = "AppTitle"
    
    // Getters with Defaults
    static var dmmsThreshold: Double {
        get { defaults.double(forKey: kDMMS) == 0 ? 70.0 : defaults.double(forKey: kDMMS) }
        set { defaults.set(newValue, forKey: kDMMS) }
    }
    
    static var messageFrequency: TimeInterval {
        get { defaults.double(forKey: kMsgFreq) == 0 ? 5.0 : defaults.double(forKey: kMsgFreq) }
        set { defaults.set(newValue, forKey: kMsgFreq) }
    }
    
    static var weatherFetchInterval: TimeInterval {
        get { defaults.double(forKey: kWeatherInterval) == 0 ? 300.0 : defaults.double(forKey: kWeatherInterval) }
        set { defaults.set(newValue, forKey: kWeatherInterval) }
    }
    
    static var showSkull: Bool {
        get { defaults.object(forKey: "ShowSkull") == nil ? true : defaults.bool(forKey: "ShowSkull") }
        set { defaults.set(newValue, forKey: "ShowSkull") }
    }
    
    static var airportCallOuts: Bool {
        get { defaults.object(forKey: "AirportCallOuts") == nil ? true : defaults.bool(forKey: "AirportCallOuts") }
        set { defaults.set(newValue, forKey: "AirportCallOuts") }
    }
    
    static var autoStart: Bool {
        get { defaults.object(forKey: kAutoStart) == nil ? false : defaults.bool(forKey: kAutoStart) }
        set { defaults.set(newValue, forKey: kAutoStart) }
    }
    
    static var alertMessage: String {
        get { defaults.string(forKey: kAlertMessage) ?? "SPEED CHECK! STALL WARNING!" }
        set { defaults.set(newValue, forKey: kAlertMessage) }
    }
    
    static var appTitle: String {
        get { defaults.string(forKey: kAppTitle) ?? "DMMS Alerts" }
        set { defaults.set(newValue, forKey: kAppTitle) }
    }
    
    static var landingAltitudeBuffer: Double { return 10.0 }
    static var landingDistanceKm: Double { return 0.9 }
}
class ViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var dmmsValueLabel: UILabel!
    @IBOutlet weak var airportLabel: UILabel!
    @IBOutlet weak var dmmsPicker: UIPickerView!
    @IBOutlet weak var warningImage: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    
    // MARK: - Core Managers
    private let locationManager = LocationManager.shared
    private let motionManager = CMMotionManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    // MARK: - State
    private var gForce: Double = 1.0
    private var adjustedStallSpeed: Double = 0.0
    private var isAlertActive = false
    private var alertTimer: Timer?
    private var isPaused = true
    
    // Airport / Weather State
    private var lastStationID: String = "N/A"
    private var landingModeActive = false
    private var lastWeatherFetchTime: Date?
    private var currentMetar: MetarData?
    private var windComponent: Double = 0.0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPicker()
        setupMotionManager()
        
        // Background Load
        AirportManager.shared.loadAirports { [weak self] in
            DispatchQueue.main.async { self?.airportLabel.text = "Airports Loaded. Waiting for GPS..." }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .didUpdateLocation, object: nil)
        
        updateDMMSLabel()
        
        // Set title
        self.title = AppConfig.appTitle
        
        // Style navigation bar - white text on blue
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.barStyle = .black
        
        // Add Options button if not already there
        if navigationItem.rightBarButtonItem == nil {
            let optionsBtn = UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(openOptions))
            optionsBtn.tintColor = .white
            navigationItem.rightBarButtonItem = optionsBtn
        }
        
        // Auto-start if enabled
        if AppConfig.autoStart {
            isPaused = false
            locationManager.startMonitoring()
            statusLabel.text = "MONITORING"
            startButton.setTitle("Pause", for: .normal)
            startButton.backgroundColor = .systemRed
        }
    }
    // Add this function to handle the click
    @objc func openOptions() {
        // Instantiate the OptionsVC manually since we aren't using a segue
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // NOTE: You must go to Storyboard -> Click Options Screen -> Identity Inspector -> Set Storyboard ID to "OptionsVC"
        if let optionsVC = storyboard.instantiateViewController(withIdentifier: "OptionsVC") as? OptionsViewController {
            self.navigationController?.pushViewController(optionsVC, animated: true)
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemBlue
        warningImage.isHidden = true
        warningImage.image = UIImage(systemName: "exclamationmark.triangle.fill")
        statusLabel.text = "PAUSED"
        statusLabel.numberOfLines = 0
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.textAlignment = .center
        startButton.setTitle("Start Monitoring", for: .normal)
        startButton.backgroundColor = .systemGreen
        startButton.layer.cornerRadius = 10
        airportLabel.text = "Initializing..."
    }
    
    private func setupPicker() {
        dmmsPicker.dataSource = self
        dmmsPicker.delegate = self
        let defaultRow = Int(AppConfig.dmmsThreshold) - 1
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
            // Simulator Fallback
            self.gForce = 1.0
            self.calculateStallSpeed()
        }
    }
    
    // MARK: - Main Loop
    @objc private func updateUI() {
        guard !isPaused, let location = locationManager.currentLocation else { return }
        print("GPS: \(location.coordinate.latitude), \(location.coordinate.longitude)")
	
        let groundSpeed = locationManager.currentSpeed
        let alt = locationManager.currentAltitude
        let head = locationManager.currentHeading
        
        // Calculate Effective Airspeed (IAS)
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
        checkAlerts(currentSpeed: effectiveAirspeed)
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
        if distKm <= AppConfig.landingDistanceKm && altitudeDiff < AppConfig.landingAltitudeBuffer {
            landingModeActive = true
            statusLabel.text = "LANDING MODE"
            statusLabel.textColor = .systemYellow
        } else {
            landingModeActive = false
            // Only reset status text if not showing METAR status
            if windComponent == 0 {
                statusLabel.text = "MONITORING"
                statusLabel.textColor = .white
            }
        }
        
        // TTS Logic
        if airport.id != lastStationID {
            lastStationID = airport.id
            let speechText = String(format: "%@, %.0f miles", airport.id, distMiles)
            speak(text: speechText)
            
            // New Airport -> Fetch Immediately
            performWeatherFetch(for: airport, location: location)
        } else {
            // Same Airport -> Throttle Fetch
            let timeSince = lastWeatherFetchTime?.timeIntervalSinceNow ?? -99999
            // Configurable Interval (e.g. 300s)
            if timeSince < -AppConfig.weatherFetchInterval {
                performWeatherFetch(for: airport, location: location)
            }
        }
    }
    

    private func performWeatherFetch(for airport: Airport, location: CLLocation) {
        lastWeatherFetchTime = Date()
        
        // Skip "US-" IDs
        if airport.id.hasPrefix("US-") || airport.id.count > 4 {
            print("Skipping ID Fetch for private/local strip \(airport.id). Using BBox.")
            fetchBBox(location: location)
            return
        }
        
        print("Fetching Weather for \(airport.id)...")
        
        // Explicitly type the closure parameter: (MetarData?)
        WeatherManager.shared.fetchMetar(for: airport.id) { [weak self] (metar: MetarData?) in
            if let metar = metar, let _ = metar.wdir, let _ = metar.wspd {
                self?.updateMetarUI(metar)
            } else {
                print("Primary METAR failed. Searching BBox...")
                self?.fetchBBox(location: location)
            }
        }
    }
    
    private func updateMetarUI(_ metar: MetarData) {
        DispatchQueue.main.async {
            self.currentMetar = metar
            let heading = self.locationManager.currentHeading
            self.windComponent = WeatherManager.shared.calculateWindComponent(heading: heading, metar: metar)
            
            // NO updateUI() call here. Prevents Infinite Loop.
            print("Weather Updated: \(metar.icaoId ?? "?") | Wind Comp: \(self.windComponent)")
        }
    }
    
    private func calculateStallSpeed() {
        let loadFactor = max(0.1, abs(gForce))
        adjustedStallSpeed = AppConfig.dmmsThreshold * sqrt(loadFactor)
    }
    
    private func checkAlerts(currentSpeed: Double) {
        if landingModeActive {
            if isAlertActive { stopAlert() }
            return
        }
        
        if currentSpeed < adjustedStallSpeed {
            if !isAlertActive { startAlert() }
        } else {
            if isAlertActive { stopAlert() }
        }
    }
    
    private func startAlert() {
        guard !isAlertActive else { return }
        isAlertActive = true
        warningImage.isHidden = !AppConfig.showSkull
        view.backgroundColor = .systemRed
        
        let text = AppConfig.alertMessage
        speak(text: text)
        
        // Loop Alert (Configurable Frequency)
        alertTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.messageFrequency, repeats: true) { [weak self] _ in
            self?.speak(text: text)
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
    
    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 1.0
        let englishVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.starts(with: "en") })
        let anyVoice = AVSpeechSynthesisVoice.speechVoices().first
        utterance.voice = englishVoice ?? anyVoice
        
        do { try AVAudioSession.sharedInstance().setActive(true) } catch {}
        synthesizer.speak(utterance)
    }
    private func fetchBBox(location: CLLocation) {
     WeatherManager.shared.fetchMetarExpanding(location: location) { [weak self] (boxMetar: MetarData?) in
         if let boxMetar = boxMetar, let id = boxMetar.icaoId {
             print("BBox Rescue Successful: Found \(id)")
             self?.updateMetarUI(boxMetar)
         } else {
             print("BBox Expanding Search failed completely. No valid stations found.")
         }
     }
 }
    // MARK: - Actions
    @IBAction func startButtonTapped(_ sender: UIButton) {
        isPaused.toggle()
        if isPaused {
            locationManager.stopMonitoring()
            statusLabel.text = "PAUSED"
            statusLabel.textColor = .white
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
        dmmsValueLabel.text = "DMMS: \(Int(AppConfig.dmmsThreshold)) KTS"
    }
}
// MARK: - Picker Delegate
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return 270 }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { return "\(row + 1) KTS" }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        AppConfig.dmmsThreshold = Double(row + 1) // Saves to UserDefaults
        updateDMMSLabel()
        calculateStallSpeed()
        checkAlerts(currentSpeed: locationManager.currentSpeed)
    }
}
