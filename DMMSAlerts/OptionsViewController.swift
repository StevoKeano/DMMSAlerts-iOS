//
//  OptionsViewController.swift
//  DMMSAlerts
//
//  Created by Stephen Kean on 2/18/26.
//

import UIKit

class OptionsViewController: UIViewController {
    
    // MARK: - Outlets (storyboard elements)
    @IBOutlet weak var frequencyField: UITextField!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var calloutsSwitch: UISwitch!
    @IBOutlet weak var skullSwitch: UISwitch!
    @IBOutlet weak var autoStartSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    
    // Programmatic elements
    private var weatherIntervalField: UITextField!
    private var frequencyLabel: UILabel!
    private var messageLabel: UILabel!
    private var titleLabel: UILabel!
    private var calloutsLabel: UILabel!
    private var skullLabel: UILabel!
    private var autoStartLabel: UILabel!
    private var weatherIntervalLabel: UILabel!
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Always use programmatic UI for now
        setupUIManually()
        loadSettings()
    }
    
    private func setupUIManually() {
        view.backgroundColor = .systemBackground
        title = "Options"
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
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
        
        var previousAnchor: NSLayoutYAxisAnchor = contentView.topAnchor
        let padding: CGFloat = 16
        let fieldHeight: CGFloat = 44
        let labelHeight: CGFloat = 20
        
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
        
        // Show Skull
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
        
        // Title
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
        
        // Message
        messageLabel = createLabel(text: "Alert Message:")
        contentView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: previousAnchor, constant: padding),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            messageLabel.heightAnchor.constraint(equalToConstant: labelHeight)
        ])
        
        messageField = createTextField(placeholder: "SPEED CHECK! STALL WARNING!")
        contentView.addSubview(messageField)
        NSLayoutConstraint.activate([
            messageField.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            messageField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            messageField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            messageField.heightAnchor.constraint(equalToConstant: fieldHeight)
        ])
        previousAnchor = messageField.bottomAnchor
        
        // Save Button
        saveButton = UIButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save Options", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(saveTapped(_:)), for: .touchUpInside)
        contentView.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: previousAnchor, constant: padding * 2),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
        
        addDoneButtonOnKeyboard()
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }
    
    private func createTextField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.keyboardType = .numbersAndPunctuation
        return field
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Options"
        
        saveButton.layer.cornerRadius = 10
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitle("Save Options", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        
        addDoneButtonOnKeyboard()
    }
    
    private func loadSettings() {
        frequencyField?.text = String(format: "%.0f", AppConfig.messageFrequency)
        weatherIntervalField?.text = String(format: "%.0f", AppConfig.weatherFetchInterval)
        
        calloutsSwitch?.isOn = AppConfig.airportCallOuts
        skullSwitch?.isOn = AppConfig.showSkull
        autoStartSwitch?.isOn = AppConfig.autoStart
        
        messageField?.text = AppConfig.alertMessage
        titleField?.text = AppConfig.appTitle
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        guard let freqText = frequencyField?.text, let freq = Double(freqText), freq > 0 else {
            showAlert(message: "Frequency must be > 0 seconds")
            return
        }
        
        guard let weatherText = weatherIntervalField?.text, let weather = Double(weatherText), weather > 0 else {
            showAlert(message: "Weather interval must be > 0 seconds")
            return
        }
        
        AppConfig.messageFrequency = freq
        AppConfig.weatherFetchInterval = weather
        AppConfig.airportCallOuts = calloutsSwitch?.isOn ?? true
        AppConfig.showSkull = skullSwitch?.isOn ?? true
        AppConfig.autoStart = autoStartSwitch?.isOn ?? false
        
        if let message = messageField?.text, !message.isEmpty {
            AppConfig.alertMessage = message
        }
        
        if let title = titleField?.text, !title.isEmpty {
            AppConfig.appTitle = title
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func addDoneButtonOnKeyboard() {
        let doneToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
        doneToolbar.items = [flexSpace, done]
        doneToolbar.sizeToFit()
        
        frequencyField?.inputAccessoryView = doneToolbar
        weatherIntervalField?.inputAccessoryView = doneToolbar
        messageField?.inputAccessoryView = doneToolbar
        titleField?.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        view.endEditing(true)
    }
}
