//
//  OptionsViewController.swift
//  DMMSAlerts
//
//  Created by Stephen Kean on 2/18/26.
//

import UIKit

class OptionsViewController: UIViewController {
    
    // Programmatic UI elements
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    private var frequencyField: UITextField!
    private var weatherIntervalField: UITextField!
    private var messageField: UITextField!
    private var titleField: UITextField!
    
    private var calloutsSwitch: UISwitch!
    private var skullSwitch: UISwitch!
    private var autoStartSwitch: UISwitch!
    private var groundModeSwitch: UISwitch!
    private var trafficMilesField: UITextField!
    private var traffic700Field: UITextField!
    private var traffic500Field: UITextField!
    private var traffic100Field: UITextField!
    private var saveButton: UIButton!
    
    private var frequencyLabel: UILabel!
    private var weatherIntervalLabel: UILabel!
    private var messageLabel: UILabel!
    private var titleLabel: UILabel!
    private var calloutsLabel: UILabel!
    private var skullLabel: UILabel!
    private var autoStartLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Options"
        
        // ScrollView
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // ContentView
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        let padding: CGFloat = 16
        let fieldHeight: CGFloat = 44
        let labelHeight: CGFloat = 24
        var previousAnchor: NSLayoutYAxisAnchor = contentView.topAnchor
        
        // Frequency
        frequencyLabel = createLabel(text: "Alert Frequency (sec):")
        contentView.addSubview(frequencyLabel)
        NSLayoutConstraint.activate([
            frequencyLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            frequencyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            frequencyLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        frequencyField = createTextField(placeholder: "5")
        contentView.addSubview(frequencyField)
        NSLayoutConstraint.activate([
            frequencyField.topAnchor.constraint(equalTo: frequencyLabel.bottomAnchor, constant: 4),
            frequencyField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            frequencyField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            frequencyField.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
        previousAnchor = frequencyField.bottomAnchor
        
        // Weather Interval
        weatherIntervalLabel = createLabel(text: "Weather Fetch (sec):")
        contentView.addSubview(weatherIntervalLabel)
        NSLayoutConstraint.activate([
            weatherIntervalLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            weatherIntervalLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            weatherIntervalLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        weatherIntervalField = createTextField(placeholder: "300")
        contentView.addSubview(weatherIntervalField)
        NSLayoutConstraint.activate([
            weatherIntervalField.topAnchor.constraint(equalTo: weatherIntervalLabel.bottomAnchor, constant: 4),
            weatherIntervalField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            weatherIntervalField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            weatherIntervalField.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
        previousAnchor = weatherIntervalField.bottomAnchor
        
        // Airport Callouts
        calloutsLabel = createLabel(text: "Airport Callouts")
        contentView.addSubview(calloutsLabel)
        NSLayoutConstraint.activate([
            calloutsLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            calloutsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            calloutsLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        calloutsSwitch = UISwitch()
        calloutsSwitch.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(calloutsSwitch)
        NSLayoutConstraint.activate([
            calloutsSwitch.centerYAnchor.constraint(equalTo: calloutsLabel.centerYAnchor),
            calloutsSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        previousAnchor = calloutsLabel.bottomAnchor
        
        // Skull
        skullLabel = createLabel(text: "Show Warning Icon")
        contentView.addSubview(skullLabel)
        NSLayoutConstraint.activate([
            skullLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            skullLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            skullLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        skullSwitch = UISwitch()
        skullSwitch.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(skullSwitch)
        NSLayoutConstraint.activate([
            skullSwitch.centerYAnchor.constraint(equalTo: skullLabel.centerYAnchor),
            skullSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        previousAnchor = skullLabel.bottomAnchor
        
        // Auto Start
        autoStartLabel = createLabel(text: "Auto-Start Monitoring")
        contentView.addSubview(autoStartLabel)
        NSLayoutConstraint.activate([
            autoStartLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            autoStartLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            autoStartLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        autoStartSwitch = UISwitch()
        autoStartSwitch.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(autoStartSwitch)
        NSLayoutConstraint.activate([
            autoStartSwitch.centerYAnchor.constraint(equalTo: autoStartLabel.centerYAnchor),
            autoStartSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        previousAnchor = autoStartLabel.bottomAnchor
        
        // Ground Mode
        let groundModeLabel = createLabel(text: "Ground/Car Mode")
        contentView.addSubview(groundModeLabel)
        NSLayoutConstraint.activate([
            groundModeLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            groundModeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            groundModeLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        groundModeSwitch = UISwitch()
        groundModeSwitch.translatesAutoresizingMaskIntoConstraints = false
        groundModeSwitch.addTarget(self, action: #selector(groundModeChanged(_:)), for: .valueChanged)
        contentView.addSubview(groundModeSwitch)
        NSLayoutConstraint.activate([
            groundModeSwitch.centerYAnchor.constraint(equalTo: groundModeLabel.centerYAnchor),
            groundModeSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        previousAnchor = groundModeLabel.bottomAnchor
        
        // App Title
        titleLabel = createLabel(text: "App Title:")
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        titleField = createTextField(placeholder: "DMMS Alerts")
        contentView.addSubview(titleField)
        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            titleField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            titleField.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
        previousAnchor = titleField.bottomAnchor
        
        // Alert Message
        messageLabel = createLabel(text: "Alert Message:")
        contentView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            messageLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        messageField = createTextField(placeholder: "SPEED CHECK! You are going to FALL OUT OF THE SKY LIKE A PIANO !!!AHHHHhhhhhh....")
        contentView.addSubview(messageField)
        NSLayoutConstraint.activate([
            messageField.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            messageField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            messageField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            messageField.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
        previousAnchor = messageField.bottomAnchor
        
        // Traffic Pattern Settings Section
        let trafficHeader = createLabel(text: "Traffic Pattern Callouts")
        trafficHeader.font = .boldSystemFont(ofSize: 18)
        contentView.addSubview(trafficHeader)
        NSLayoutConstraint.activate([
            trafficHeader.topAnchor.constraint(equalTo: previousAnchor, constant: padding * 2),
            trafficHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding)
        ])
        previousAnchor = trafficHeader.bottomAnchor
        
        // Traffic Pattern Distance
        let trafficMilesLabel = createLabel(text: "Within (miles):")
        contentView.addSubview(trafficMilesLabel)
        NSLayoutConstraint.activate([
            trafficMilesLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            trafficMilesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            trafficMilesLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        trafficMilesField = createTextField(placeholder: "3")
        trafficMilesField.keyboardType = .numberPad
        contentView.addSubview(trafficMilesField)
        NSLayoutConstraint.activate([
            trafficMilesField.topAnchor.constraint(equalTo: trafficMilesLabel.bottomAnchor, constant: 4),
            trafficMilesField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            trafficMilesField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            trafficMilesField.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
        previousAnchor = trafficMilesField.bottomAnchor
        
        // 700ft Callout Text
        let traffic700Label = createLabel(text: "700ft Callout:")
        contentView.addSubview(traffic700Label)
        NSLayoutConstraint.activate([
            traffic700Label.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            traffic700Label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            traffic700Label.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        traffic700Field = createTextField(placeholder: "Traffic pattern, 700 feet")
        contentView.addSubview(traffic700Field)
        NSLayoutConstraint.activate([
            traffic700Field.topAnchor.constraint(equalTo: traffic700Label.bottomAnchor, constant: 4),
            traffic700Field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            traffic700Field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            traffic700Field.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
        previousAnchor = traffic700Field.bottomAnchor
        
        // 500ft Callout Text
        let traffic500Label = createLabel(text: "500ft Callout:")
        contentView.addSubview(traffic500Label)
        NSLayoutConstraint.activate([
            traffic500Label.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            traffic500Label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            traffic500Label.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        traffic500Field = createTextField(placeholder: "Traffic pattern, 500 feet")
        contentView.addSubview(traffic500Field)
        NSLayoutConstraint.activate([
            traffic500Field.topAnchor.constraint(equalTo: traffic500Label.bottomAnchor, constant: 4),
            traffic500Field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            traffic500Field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            traffic500Field.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
        previousAnchor = traffic500Field.bottomAnchor
        
        // 100ft Callout Text
        let traffic100Label = createLabel(text: "100ft Callout:")
        contentView.addSubview(traffic100Label)
        NSLayoutConstraint.activate([
            traffic100Label.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            traffic100Label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            traffic100Label.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        traffic100Field = createTextField(placeholder: "Traffic pattern, 100 feet")
        contentView.addSubview(traffic100Field)
        NSLayoutConstraint.activate([
            traffic100Field.topAnchor.constraint(equalTo: traffic100Label.bottomAnchor, constant: 4),
            traffic100Field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            traffic100Field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            traffic100Field.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
        previousAnchor = traffic100Field.bottomAnchor
        
        // Save Button
        saveButton = UIButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save Options", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        contentView.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: previousAnchor, constant: padding * 2),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
        
        addDoneButtonToKeyboard()
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }
    
    private func createTextField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 16)
        return field
    }
    
    private func loadSettings() {
        frequencyField.text = String(format: "%.0f", AppConfig.messageFrequency)
        weatherIntervalField.text = String(format: "%.0f", AppConfig.weatherFetchInterval)
        
        calloutsSwitch.isOn = AppConfig.airportCallOuts
        skullSwitch.isOn = AppConfig.showSkull
        autoStartSwitch.isOn = AppConfig.autoStart
        groundModeSwitch.isOn = AppConfig.groundMode
        
        messageField.text = AppConfig.alertMessage
        titleField.text = AppConfig.appTitle
        
        trafficMilesField.text = String(format: "%.0f", AppConfig.trafficPatternMiles)
        traffic700Field.text = AppConfig.traffic700ftText
        traffic500Field.text = AppConfig.traffic500ftText
        traffic100Field.text = AppConfig.traffic100ftText
    }
    
    @objc private func saveTapped() {
        guard let freqText = frequencyField.text, let freq = Double(freqText), freq > 0 else {
            showAlert(message: "Frequency must be > 0 seconds")
            return
        }
        
        guard let weatherText = weatherIntervalField.text, let weather = Double(weatherText), weather > 0 else {
            showAlert(message: "Weather interval must be > 0 seconds")
            return
        }
        
        AppConfig.messageFrequency = freq
        AppConfig.weatherFetchInterval = weather
        AppConfig.airportCallOuts = calloutsSwitch.isOn
        AppConfig.showSkull = skullSwitch.isOn
        AppConfig.autoStart = autoStartSwitch.isOn
        AppConfig.groundMode = groundModeSwitch.isOn
        
        if let message = messageField.text, !message.isEmpty {
            AppConfig.alertMessage = message
        }
        
        if let titleText = titleField.text, !titleText.isEmpty {
            AppConfig.appTitle = titleText
        }
        
        // Traffic Pattern Settings
        if let milesText = trafficMilesField.text, let miles = Double(milesText), miles > 0 {
            AppConfig.trafficPatternMiles = miles
        }
        
        if let text700 = traffic700Field.text, !text700.isEmpty {
            AppConfig.traffic700ftText = text700
        }
        
        if let text500 = traffic500Field.text, !text500.isEmpty {
            AppConfig.traffic500ftText = text500
        }
        
        if let text100 = traffic100Field.text, !text100.isEmpty {
            AppConfig.traffic100ftText = text100
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func groundModeChanged(_ sender: UISwitch) {
        AppConfig.groundMode = sender.isOn
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func addDoneButtonToKeyboard() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        toolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexSpace, done]
        toolbar.sizeToFit()
        
        frequencyField.inputAccessoryView = toolbar
        weatherIntervalField.inputAccessoryView = toolbar
        messageField.inputAccessoryView = toolbar
        titleField.inputAccessoryView = toolbar
        trafficMilesField.inputAccessoryView = toolbar
        traffic700Field.inputAccessoryView = toolbar
        traffic500Field.inputAccessoryView = toolbar
        traffic100Field.inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
