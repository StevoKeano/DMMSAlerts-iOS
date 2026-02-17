//
//  ViewController.swift
//  DMMSAlerts
//
//  Created by Stephen Kean on 2/16/26.
//
import UIKit
import CoreLocation
import CoreMotion
import AVFoundation
class ViewController: UIViewController {
    // MARK: - Outlets (You must link these in Storyboard!)
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var dmmsValueLabel: UILabel!
    @IBOutlet weak var dmmsPicker: UIPickerView!
    @IBOutlet weak var warningImage: UIImageView!
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    // MARK: - Properties
    private let locationManager = LocationManager.shared
    private let motionManager = CMMotionManager()
    private let synthesizer = AVSpeechSynthesizer()
    private let defaults = UserDefaults.standard
    
    // Config
    private var dmmsThreshold: Double = 70.0 // Default
    private var gForce: Double = 1.0
    private var adjustedStallSpeed: Double = 0.0
    private var isAlertActive = false
    private var alertTimer: Timer?
    private var isPaused = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPicker()
        setupMotionManager()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .didUpdateLocation, object: nil)
        
        // Load DMMS Setting
        if let savedDMMS = defaults.value(forKey: "DMMSValue") as? Double {
            dmmsThreshold = savedDMMS
        }
        updateDMMSLabel()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBlue // Sky Gradient
        warningImage.isHidden = true
        warningImage.image = UIImage(systemName: "exclamationmark.triangle.fill") // Placeholder for skull
        statusLabel.text = "PAUSED"
        startButton.setTitle("Start Monitoring", for: .normal)
        startButton.backgroundColor = .systemGreen
        startButton.layer.cornerRadius = 10
    }
    
    private func setupPicker() {
        dmmsPicker.dataSource = self
        dmmsPicker.delegate = self
        // Set default selection
        let defaultRow = Int(dmmsThreshold) - 1
        dmmsPicker.selectRow(defaultRow, inComponent: 0, animated: false)
    }
    
    private func setupMotionManager() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data else { return }
                
                // Calculate G-Force
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                let totalG = sqrt(x*x + y*y + z*z)
                
                // Low-pass filter (simple moving average could be better)
                self.gForce = totalG
                
                // Calculate Stall Speed
                self.calculateStallSpeed()
            }
        }
    }
    
    // MARK: - Core Logic
    
    @objc private func updateUI() {
        guard !isPaused else { return }
        
        let speed = locationManager.currentSpeed
        let alt = locationManager.currentAltitude
        let head = locationManager.currentHeading
        
        speedLabel.text = String(format: "%.0f KTS", speed)
        altitudeLabel.text = String(format: "%.0f FT", alt)
        headingLabel.text = String(format: "HDG: %.0f°", head)
        
        checkAlerts(currentSpeed: speed)
    }
    
    private func calculateStallSpeed() {
        // Formula: StallSpeed = ZeroGStallSpeed * Sqrt(LoadFactor)
        // LoadFactor is approx G-Force in coordinated flight
        let loadFactor = max(0.1, abs(gForce)) // Avoid sqrt(negative)
        adjustedStallSpeed = dmmsThreshold * sqrt(loadFactor)
        
        // Update Label (Optional debugging)
        // print("G: \(gForce), Adj Stall: \(adjustedStallSpeed)")
    }
    
    private func checkAlerts(currentSpeed: Double) {
        // Trigger if Speed < Adjusted Stall Speed
        if currentSpeed < adjustedStallSpeed {
            if !isAlertActive {
                startAlert()
            }
        } else {
            if isAlertActive {
                stopAlert()
            }
        }
    }
    
    private func startAlert() {
        isAlertActive = true
        warningImage.isHidden = false
        view.backgroundColor = .systemRed // Visual Flash
        
        // TTS
        let utterance = AVSpeechUtterance(string: "SPEED CHECK! STALL WARNING!")
        utterance.rate = 0.5
        utterance.volume = 1.0
        synthesizer.speak(utterance)
        
        // Loop Alert
        alertTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.synthesizer.speak(utterance)
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
// MARK: - Picker Delegate
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 270 // 1 to 270 knots
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1) KTS"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        dmmsThreshold = Double(row + 1)
        defaults.set(dmmsThreshold, forKey: "DMMSValue")
        updateDMMSLabel()
    }
}
