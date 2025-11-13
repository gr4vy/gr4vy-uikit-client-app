//
//  FieldsViewController.swift
//  Gr4vy UIKit Sample App
//
//  Created by Gr4vy
//

import UIKit
import gr4vy_swift

enum PaymentMethodType: String, CaseIterable {
    case card = "card"
    case id = "id"
    
    var displayName: String {
        switch self {
        case .card: return "Card"
        case .id: return "ID"
        }
    }
}

// MARK: - Theme Options
private enum ThemeOption: String, CaseIterable {
    case none
    case redBlue
    case orangePurple
    case greenYellow
    
    var displayName: String {
        switch self {
        case .none: return "No Theme"
        case .redBlue: return "Red / Blue"
        case .orangePurple: return "Orange / Purple"
        case .greenYellow: return "Green / Yellow"
        }
    }
}

// MARK: - Test Card Options
private enum TestCard: String, CaseIterable {
    case custom
    
    // Frictionless (AUTHENTICATED_APPLICATION_FRICTIONLESS)
    case visaFrictionless
    case mastercardFrictionless
    case amexFrictionless
    case dinersFrictionless
    case jcbFrictionless
    
    // Challenge (APPLICATION_CHALLENGE)
    case visaChallenge
    case mastercardChallenge
    case amexChallenge
    case dinersChallenge
    case jcbChallenge
    
    var displayName: String {
        switch self {
        case .custom: return "Custom"
        case .visaFrictionless: return "Visa Frictionless Test Card"
        case .visaChallenge: return "Visa Challenge Test Card"
        case .mastercardFrictionless: return "Mastercard Frictionless Test Card"
        case .mastercardChallenge: return "Mastercard Challenge Test Card"
        case .amexFrictionless: return "Amex Frictionless Test Card"
        case .amexChallenge: return "Amex Challenge Test Card"
        case .dinersFrictionless: return "Diners Frictionless Test Card"
        case .dinersChallenge: return "Diners Challenge Test Card"
        case .jcbFrictionless: return "JCB Frictionless Test Card"
        case .jcbChallenge: return "JCB Challenge Test Card"
        }
    }
    
    var cardNumber: String {
        switch self {
        case .custom: return ""
            
        // AUTHENTICATED_APPLICATION_FRICTIONLESS
        case .visaFrictionless: return "4556557955726624"
        case .mastercardFrictionless: return "5333259155643223"
        case .amexFrictionless: return "341502098634895"
        case .dinersFrictionless: return "36000000000008"
        case .jcbFrictionless: return "3528000000000056"
            
        // APPLICATION_CHALLENGE
        case .visaChallenge: return "4024007189449340"
        case .mastercardChallenge: return "5267648608924299"
        case .amexChallenge: return "349531373081938"
        case .dinersChallenge: return "36000002000048"
        case .jcbChallenge: return "3528000000000148"
        }
    }
    
    var expirationDate: String {
        switch self {
        case .custom: return ""
        default: return "01/30"
        }
    }
    
    var cvv: String {
        switch self {
        case .custom: return ""
        // frictionless
        case .visaFrictionless, .mastercardFrictionless, .amexFrictionless,
             .dinersFrictionless, .jcbFrictionless:
            return "123"
        // challenge
        case .visaChallenge, .mastercardChallenge, .amexChallenge,
             .dinersChallenge, .jcbChallenge:
            return "456"
        }
    }
}

class FieldsViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = UIView()
    private let errorLabel = UILabel()
    
    // Form fields
    private let checkoutSessionIdTextField = UITextField()
    private let paymentMethodSegmentedControl = UISegmentedControl(items: PaymentMethodType.allCases.map { $0.displayName })
    
    // Card fields
    private let cardNumberTextField = UITextField()
    private let expirationDateTextField = UITextField()
    private let securityCodeTextField = UITextField()
    
    // ID fields
    private let paymentMethodIdTextField = UITextField()
    private let idSecurityCodeTextField = UITextField()
    
    // 3DS Settings
    private let authenticateSwitch = UISwitch()
    private var selectedTestCard: TestCard = .custom
    private var selectedTheme: ThemeOption = .none
    private let sdkMaxTimeoutTextField = UITextField()
    
    // Test Card Picker
    private let testCardPicker = UIPickerView()
    private let testCardTextField = UITextField()
    
    // Theme Picker
    private let themePicker = UIPickerView()
    private let themeTextField = UITextField()
    
    // State
    private var isLoading = false
    private var selectedPaymentMethodType: PaymentMethodType = .card
    private var showingGeneralError = false
    private var generalErrorData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupErrorView()
        loadSavedData()
    }
    
    private func setupUI() {
        title = "Tokenize"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Add PUT button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "PUT",
            style: .done,
            target: self,
            action: #selector(putButtonTapped)
        )
        
        // Configure table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FieldsTextFieldTableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(FieldsSegmentedControlTableViewCell.self, forCellReuseIdentifier: "SegmentedControlCell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: "ButtonCell")
        
        view.addSubview(tableView)
        
        // Configure activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        setupFormFields()
    }
    
    private func setupTableView() {
        tableView.keyboardDismissMode = .onDrag
    }
    
    private func setupErrorView() {
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        errorView.layer.cornerRadius = 8
        errorView.isHidden = true
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textColor = UIColor.systemRed
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont.systemFont(ofSize: 14)
        
        errorView.addSubview(errorLabel)
        view.addSubview(errorView)
        
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            errorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            errorView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            errorLabel.topAnchor.constraint(equalTo: errorView.topAnchor, constant: 12),
            errorLabel.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 12),
            errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -12),
            errorLabel.bottomAnchor.constraint(equalTo: errorView.bottomAnchor, constant: -12)
        ])
    }
    
    private func setupFormFields() {
        // Session fields
        checkoutSessionIdTextField.placeholder = "checkout_session_id"
        checkoutSessionIdTextField.autocapitalizationType = .none
        checkoutSessionIdTextField.autocorrectionType = .no
        checkoutSessionIdTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Payment method segmented control
        paymentMethodSegmentedControl.selectedSegmentIndex = 0
        paymentMethodSegmentedControl.addTarget(self, action: #selector(paymentMethodSegmentedControlChanged(_:)), for: .valueChanged)
        
        // Card fields
        cardNumberTextField.placeholder = "number"
        cardNumberTextField.keyboardType = .numberPad
        cardNumberTextField.autocapitalizationType = .none
        cardNumberTextField.autocorrectionType = .no
        cardNumberTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        expirationDateTextField.placeholder = "expiration_date"
        expirationDateTextField.keyboardType = .numberPad
        expirationDateTextField.autocapitalizationType = .none
        expirationDateTextField.autocorrectionType = .no
        expirationDateTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        securityCodeTextField.placeholder = "security_code"
        securityCodeTextField.keyboardType = .numberPad
        securityCodeTextField.autocapitalizationType = .none
        securityCodeTextField.autocorrectionType = .no
        securityCodeTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // ID fields
        paymentMethodIdTextField.placeholder = "payment_method_id"
        paymentMethodIdTextField.autocapitalizationType = .none
        paymentMethodIdTextField.autocorrectionType = .no
        paymentMethodIdTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        idSecurityCodeTextField.placeholder = "security_code"
        idSecurityCodeTextField.keyboardType = .numberPad
        idSecurityCodeTextField.autocapitalizationType = .none
        idSecurityCodeTextField.autocorrectionType = .no
        idSecurityCodeTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // 3DS Settings
        authenticateSwitch.addTarget(self, action: #selector(authenticateSwitchChanged(_:)), for: .valueChanged)
        
        sdkMaxTimeoutTextField.placeholder = "SDK Max Timeout (minutes)"
        sdkMaxTimeoutTextField.keyboardType = .numberPad
        sdkMaxTimeoutTextField.autocapitalizationType = .none
        sdkMaxTimeoutTextField.autocorrectionType = .no
        sdkMaxTimeoutTextField.addTarget(self, action: #selector(sdkMaxTimeoutChanged(_:)), for: .editingChanged)
        
        // Setup pickers
        setupThemePicker()
        setupTestCardPicker()
    }
    
    private func setupThemePicker() {
        themePicker.delegate = self
        themePicker.dataSource = self
        
        themeTextField.placeholder = "Select Theme"
        themeTextField.inputView = themePicker
        themeTextField.tintColor = .clear
        themeTextField.text = selectedTheme.displayName
        
        // Add toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePickingTheme))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        themeTextField.inputAccessoryView = toolbar
    }
    
    private func setupTestCardPicker() {
        testCardPicker.delegate = self
        testCardPicker.dataSource = self
        
        testCardTextField.placeholder = "Select Test Card"
        testCardTextField.inputView = testCardPicker
        testCardTextField.tintColor = .clear
        testCardTextField.text = selectedTestCard.displayName
        
        // Add toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePickingTestCard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        testCardTextField.inputAccessoryView = toolbar
    }
    
    @objc private func donePickingTheme() {
        let row = themePicker.selectedRow(inComponent: 0)
        selectedTheme = ThemeOption.allCases[row]
        themeTextField.text = selectedTheme.displayName
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: "fields_theme")
        themeTextField.resignFirstResponder()
    }
    
    @objc private func donePickingTestCard() {
        let row = testCardPicker.selectedRow(inComponent: 0)
        let previousTestCard = selectedTestCard
        selectedTestCard = TestCard.allCases[row]
        testCardTextField.text = selectedTestCard.displayName
        UserDefaults.standard.set(selectedTestCard.rawValue, forKey: "fields_test_card")
        
        // Auto-populate card data
        if selectedTestCard != .custom {
            populateTestCardData()
        }
        
        testCardTextField.resignFirstResponder()
        
        // Update table view to show/hide Clear Form button
        // Only update if the clear button visibility needs to change
        let shouldShowClearButton = selectedTestCard != .custom
        let wasShowingClearButton = previousTestCard != .custom
        
        if shouldShowClearButton != wasShowingClearButton {
            tableView.performBatchUpdates({
                if shouldShowClearButton {
                    // Add the Clear Form button row
                    tableView.insertRows(at: [IndexPath(row: 1, section: 5)], with: .automatic)
                } else {
                    // Remove the Clear Form button row
                    tableView.deleteRows(at: [IndexPath(row: 1, section: 5)], with: .automatic)
                }
            }, completion: nil)
        }
    }
    
    private func populateTestCardData() {
        cardNumberTextField.text = selectedTestCard.cardNumber
        expirationDateTextField.text = selectedTestCard.expirationDate
        securityCodeTextField.text = selectedTestCard.cvv
        
        // Save to UserDefaults
        UserDefaults.standard.set(selectedTestCard.cardNumber, forKey: "fields_card_number")
        UserDefaults.standard.set(selectedTestCard.expirationDate, forKey: "fields_expiration_date")
        UserDefaults.standard.set(selectedTestCard.cvv, forKey: "fields_security_code")
    }
    
    @objc private func clearForm() {
        selectedTestCard = .custom
        testCardTextField.text = selectedTestCard.displayName
        cardNumberTextField.text = ""
        expirationDateTextField.text = ""
        securityCodeTextField.text = ""
        
        UserDefaults.standard.set(TestCard.custom.rawValue, forKey: "fields_test_card")
        UserDefaults.standard.set("", forKey: "fields_card_number")
        UserDefaults.standard.set("", forKey: "fields_expiration_date")
        UserDefaults.standard.set("", forKey: "fields_security_code")
        
        // Remove the Clear Form button row
        tableView.performBatchUpdates({
            tableView.deleteRows(at: [IndexPath(row: 1, section: 5)], with: .automatic)
        }, completion: nil)
    }
    
    @objc private func clearCheckoutSessionId() {
        checkoutSessionIdTextField.text = ""
        checkoutSessionIdTextField.rightViewMode = .never
        UserDefaults.standard.set("", forKey: "fields_checkout_session_id")
    }
    
    private func loadSavedData() {
        let sessionId = UserDefaults.standard.string(forKey: "fields_checkout_session_id") ?? ""
        checkoutSessionIdTextField.text = sessionId
        updateClearButtonVisibility()
        
        let savedPaymentMethodType = UserDefaults.standard.string(forKey: "fields_payment_method_type") ?? PaymentMethodType.card.rawValue
        if let paymentMethodType = PaymentMethodType(rawValue: savedPaymentMethodType) {
            selectedPaymentMethodType = paymentMethodType
            paymentMethodSegmentedControl.selectedSegmentIndex = PaymentMethodType.allCases.firstIndex(of: paymentMethodType) ?? 0
        }
        
        // Card fields
        cardNumberTextField.text = UserDefaults.standard.string(forKey: "fields_card_number") ?? ""
        expirationDateTextField.text = UserDefaults.standard.string(forKey: "fields_expiration_date") ?? ""
        securityCodeTextField.text = UserDefaults.standard.string(forKey: "fields_security_code") ?? ""
        
        // ID fields
        paymentMethodIdTextField.text = UserDefaults.standard.string(forKey: "fields_payment_method_id") ?? ""
        idSecurityCodeTextField.text = UserDefaults.standard.string(forKey: "fields_id_security_code") ?? ""
        
        // 3DS Settings
        let authenticateValue = UserDefaults.standard.object(forKey: "fields_authenticate") as? Bool ?? true
        authenticateSwitch.isOn = authenticateValue
        
        let testCardValue = UserDefaults.standard.string(forKey: "fields_test_card") ?? TestCard.custom.rawValue
        selectedTestCard = TestCard(rawValue: testCardValue) ?? .custom
        testCardTextField.text = selectedTestCard.displayName
        
        let themeValue = UserDefaults.standard.string(forKey: "fields_theme") ?? ThemeOption.none.rawValue
        selectedTheme = ThemeOption(rawValue: themeValue) ?? .none
        themeTextField.text = selectedTheme.displayName
        
        sdkMaxTimeoutTextField.text = UserDefaults.standard.string(forKey: "fields_sdk_max_timeout") ?? "5"
    }
    
    private func updateClearButtonVisibility() {
        let hasText = !(checkoutSessionIdTextField.text?.isEmpty ?? true)
        checkoutSessionIdTextField.rightViewMode = hasText ? .always : .never
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let value = textField.text ?? ""
        
        switch textField {
        case checkoutSessionIdTextField:
            UserDefaults.standard.set(value, forKey: "fields_checkout_session_id")
            updateClearButtonVisibility()
        case cardNumberTextField:
            UserDefaults.standard.set(value, forKey: "fields_card_number")
        case expirationDateTextField:
            UserDefaults.standard.set(value, forKey: "fields_expiration_date")
        case securityCodeTextField:
            UserDefaults.standard.set(value, forKey: "fields_security_code")
        case paymentMethodIdTextField:
            UserDefaults.standard.set(value, forKey: "fields_payment_method_id")
        case idSecurityCodeTextField:
            UserDefaults.standard.set(value, forKey: "fields_id_security_code")
        default:
            break
        }
    }
    
    @objc private func authenticateSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "fields_authenticate")
    }
    
    @objc private func sdkMaxTimeoutChanged(_ sender: UITextField) {
        // Filter to only allow numbers, max 5 digits
        let filtered = sender.text?.filter { $0.isNumber } ?? ""
        let limited = String(filtered.prefix(5))
        sender.text = limited
        UserDefaults.standard.set(limited, forKey: "fields_sdk_max_timeout")
    }
    
    @objc private func paymentMethodSegmentedControlChanged(_ sender: UISegmentedControl) {
        selectedPaymentMethodType = PaymentMethodType.allCases[sender.selectedSegmentIndex]
        UserDefaults.standard.set(selectedPaymentMethodType.rawValue, forKey: "fields_payment_method_type")
        tableView.reloadData()
    }
    
    @objc private func putButtonTapped() {
        sendRequest()
    }
    
    private func sendRequest() {
        isLoading = true
        errorView.isHidden = true
        activityIndicator.startAnimating()
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        // Get admin settings
        let gr4vyID = UserDefaults.standard.string(forKey: "gr4vyId")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let token = UserDefaults.standard.string(forKey: "apiToken")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let serverEnvironment = UserDefaults.standard.string(forKey: "serverEnvironment") ?? "sandbox"
        let timeoutString = UserDefaults.standard.string(forKey: "timeout") ?? ""
        
        let server: Gr4vyServer = serverEnvironment == "production" ? .production : .sandbox
        
        let gr4vy: Gr4vy?
        if let timeoutValue = Double(timeoutString.trimmingCharacters(in: .whitespacesAndNewlines)), 
           timeoutValue > 0, 
           !timeoutString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let timeoutInterval = TimeInterval(timeoutValue)
            gr4vy = try? Gr4vy(
                gr4vyId: gr4vyID,
                token: token,
                server: server,
                timeout: timeoutInterval,
                debugMode: true
            )
        } else {
            gr4vy = try? Gr4vy(
                gr4vyId: gr4vyID,
                token: token,
                server: server,
                debugMode: true
            )
        }
        
        guard let gr4vy = gr4vy else {
            showError("Failed to configure Gr4vy SDK")
            return
        }
        
        let checkoutSessionId = checkoutSessionIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Prepare payment method based on selected type
        let paymentMethod: Gr4vyPaymentMethod
        
        switch selectedPaymentMethodType {
        case .card:
            let cleanNumber = cardNumberTextField.text?.replacingOccurrences(of: " ", with: "") ?? ""
            let number = cleanNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            let expirationDate = expirationDateTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let securityCode = securityCodeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            let cardMethod = CardPaymentMethod(
                number: number,
                expirationDate: expirationDate,
                securityCode: securityCode.isEmpty ? nil : securityCode
            )
            paymentMethod = .card(cardMethod)
            
        case .id:
            let paymentMethodId = paymentMethodIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let securityCode = idSecurityCodeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            let idMethod = IdPaymentMethod(
                id: paymentMethodId,
                securityCode: securityCode.isEmpty ? nil : securityCode
            )
            paymentMethod = .id(idMethod)
        }
        
        let cardData = Gr4vyCardData(paymentMethod: paymentMethod)
        
        let authenticate = authenticateSwitch.isOn
        let sdkMaxTimeout = Int(sdkMaxTimeoutTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "5") ?? 5
        let uiCustomization = uiCustomizationForTheme(selectedTheme)
        
        gr4vy.tokenize(
            checkoutSessionId: checkoutSessionId,
            cardData: cardData,
            sdkMaxTimeoutMinutes: sdkMaxTimeout,
            authenticate: authenticate,
            uiCustomization: uiCustomization
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                
                switch result {
                case .success(let tokenizeResult):
                    self?.showCompleteResponse(tokenizeResult: tokenizeResult)
                    
                case .failure(let error):
                    self?.handleError(error, gr4vyID: gr4vyID)
                }
            }
        }
    }
    
    private func showCompleteResponse(tokenizeResult: Gr4vyTokenizeResult) {
        var completeResponse: [String: Any] = [
            "tokenized": tokenizeResult.tokenized
        ]
        
        if let authentication = tokenizeResult.authentication {
            var authenticationDict: [String: Any] = [
                "attempted": authentication.attempted,
                "user_cancelled": authentication.hasCancelled,
                "timed_out": authentication.hasTimedOut
            ]
            
            if let type = authentication.type {
                authenticationDict["type"] = type
            } else {
                authenticationDict["type"] = NSNull()
            }
            
            if let transactionStatus = authentication.transactionStatus {
                authenticationDict["transaction_status"] = transactionStatus
            } else {
                authenticationDict["transaction_status"] = NSNull()
            }
            
            completeResponse["authentication"] = authenticationDict
        } else {
            completeResponse["authentication"] = NSNull()
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: completeResponse, options: [.prettyPrinted, .sortedKeys])
            let responseVC = JSONResponseViewController()
            responseVC.responseData = jsonData
            navigationController?.pushViewController(responseVC, animated: true)
        } catch {
            showError("Success, but failed to format response: \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ error: Error, gr4vyID: String) {
        if let gr4vyError = error as? Gr4vyError {
            switch gr4vyError {
            case .invalidGr4vyId:
                showError("Invalid Gr4vy ID: \(gr4vyError.localizedDescription)")
            case .badURL(let url):
                showError("Bad URL: \(url)")
            case .httpError(let statusCode, let responseData, _):
                let responseVC = JSONResponseViewController()
                responseVC.responseData = responseData
                responseVC.errorStatusCode = statusCode
                
                if statusCode == 400 {
                    showError("Bad Request (400) - Tap to view details", canTapForDetails: true, responseData: responseData, statusCode: statusCode)
                } else {
                    showError("HTTP Error \(statusCode) - Tap to view details", canTapForDetails: true, responseData: responseData, statusCode: statusCode)
                }
            case .networkError(let urlError):
                handleNetworkError(urlError, gr4vyID: gr4vyID)
            case .decodingError(let message):
                showError("Decoding error: \(message)")
            case .threeDSError(let message):
                showError("3DS error: \(message)")
            case .uiContextError(let message):
                showError("UI context error: \(message)")
            }
        } else {
            handleNetworkError(error, gr4vyID: gr4vyID)
        }
    }
    
    private func handleNetworkError(_ error: Error, gr4vyID: String) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotFindHost:
                showError("Cannot find server. Please check your Merchant ID (\(gr4vyID)). The URL being called is: https://api.\(gr4vyID).gr4vy.app/tokenize")
            case .notConnectedToInternet:
                showError("No internet connection. Please check your network settings.")
            case .timedOut:
                showError("Request timed out. Please try again.")
            case .badServerResponse:
                showError("Server error. Please check your API token and try again.")
            default:
                showError("Network error: \(urlError.localizedDescription)")
            }
        } else {
            showError("Failed to tokenize: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String, canTapForDetails: Bool = false, responseData: Data? = nil, statusCode: Int? = nil) {
        errorLabel.text = message
        errorView.isHidden = false
        
        if canTapForDetails {
            errorView.gestureRecognizers?.removeAll()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showErrorDetails))
            errorView.addGestureRecognizer(tapGesture)
            
            // Store error details
            if let data = responseData, let code = statusCode {
                let responseVC = JSONResponseViewController()
                responseVC.responseData = data
                responseVC.errorStatusCode = code
                // Store reference for later use
                objc_setAssociatedObject(self, &AssociatedKeys.errorResponseViewController, responseVC, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    @objc private func showErrorDetails() {
        if let responseVC = objc_getAssociatedObject(self, &AssociatedKeys.errorResponseViewController) as? JSONResponseViewController {
            navigationController?.pushViewController(responseVC, animated: true)
        }
    }
}

// MARK: - Associated Keys
private struct AssociatedKeys {
    static var errorResponseViewController = "errorResponseViewController"
}

// MARK: - UIPickerView DataSource and Delegate
extension FieldsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == themePicker {
            return ThemeOption.allCases.count
        } else if pickerView == testCardPicker {
            return TestCard.allCases.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == themePicker {
            return ThemeOption.allCases[row].displayName
        } else if pickerView == testCardPicker {
            return TestCard.allCases[row].displayName
        }
        return nil
    }
}

// MARK: - TableView DataSource and Delegate
extension FieldsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Session, Theme, SDK Settings, Payment Method Type = 4 base sections
        var sections = 4
        
        if selectedPaymentMethodType == .card {
            sections += 4 // Authentication, Test Cards, Card Details, (Clear button handled as extra row)
        } else if selectedPaymentMethodType == .id {
            sections += 1 // ID Details
        }
        
        return sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Session (checkout_session_id)
        case 1: return 1 // Theme
        case 2: return 1 // SDK Settings
        case 3: return 1 // Payment Method Type
        default:
            if selectedPaymentMethodType == .card {
                switch section {
                case 4: return 1 // Authentication toggle
                case 5: return selectedTestCard != .custom ? 2 : 1 // Test Card picker + Clear button if needed
                case 6: return 3 // Card details (number, expiration, cvv)
                default: return 0
                }
            } else if selectedPaymentMethodType == .id {
                switch section {
                case 4: return 2 // ID details (id, security_code)
                default: return 0
                }
            }
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Session"
        case 1: return "3DS Theme"
        case 2: return "SDK Settings"
        case 3: return "Payment Method Type"
        default:
            if selectedPaymentMethodType == .card {
                switch section {
                case 4: return "Authentication"
                case 5: return "Test Cards"
                case 6: return "Card Details"
                default: return nil
                }
            } else if selectedPaymentMethodType == .id {
                switch section {
                case 4: return "ID Details"
                default: return nil
                }
            }
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // Session
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! FieldsTextFieldTableViewCell
            
            // Add clear button
            let clearButton = UIButton(type: .custom)
            clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            clearButton.tintColor = .gray
            clearButton.addTarget(self, action: #selector(clearCheckoutSessionId), for: .touchUpInside)
            clearButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            
            checkoutSessionIdTextField.rightView = clearButton
            updateClearButtonVisibility()
            
            cell.configure(with: checkoutSessionIdTextField)
            return cell
            
        case 1:
            // Theme
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! FieldsTextFieldTableViewCell
            cell.configure(with: themeTextField)
            return cell
            
        case 2:
            // SDK Settings
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! FieldsTextFieldTableViewCell
            cell.configure(with: sdkMaxTimeoutTextField)
            return cell
            
        case 3:
            // Payment Method Type
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlCell", for: indexPath) as! FieldsSegmentedControlTableViewCell
            cell.configure(with: paymentMethodSegmentedControl, title: "")
            return cell
            
        default:
            if selectedPaymentMethodType == .card {
                switch indexPath.section {
                case 4:
                    // Authentication
                    let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
                    cell.configure(with: authenticateSwitch, title: "Authenticate")
                    return cell
                    
                case 5:
                    // Test Cards
                    if indexPath.row == 0 {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! FieldsTextFieldTableViewCell
                        cell.configure(with: testCardTextField)
                        return cell
                    } else {
                        // Clear Form button
                        let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonTableViewCell
                        cell.configure(title: "Clear Form", color: .systemRed) { [weak self] in
                            self?.clearForm()
                        }
                        return cell
                    }
                    
                case 6:
                    // Card Details
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! FieldsTextFieldTableViewCell
                    switch indexPath.row {
                    case 0: cell.configure(with: cardNumberTextField)
                    case 1: cell.configure(with: expirationDateTextField)
                    case 2: cell.configure(with: securityCodeTextField)
                    default: break
                    }
                    return cell
                    
                default:
                    return UITableViewCell()
                }
            } else if selectedPaymentMethodType == .id {
                switch indexPath.section {
                case 4:
                    // ID Details
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! FieldsTextFieldTableViewCell
                    switch indexPath.row {
                    case 0: cell.configure(with: paymentMethodIdTextField)
                    case 1: cell.configure(with: idSecurityCodeTextField)
                    default: break
                    }
                    return cell
                    
                default:
                    return UITableViewCell()
                }
            }
            return UITableViewCell()
        }
    }
}

// MARK: - 3DS Theme Builders
extension FieldsViewController {
    
    private func uiCustomizationForTheme(_ option: ThemeOption) -> Gr4vyThreeDSUiCustomizationMap? {
        switch option {
        case .none:
            return nil
        case .redBlue:
            return buildRedBlueTheme()
        case .orangePurple:
            return buildOrangePurpleTheme()
        case .greenYellow:
            return buildGreenYellowTheme()
        }
    }
    
    private func buildRedBlueTheme() -> Gr4vyThreeDSUiCustomizationMap {
        let light = Gr4vyThreeDSUiCustomization(
            label: .init(
                textFontName: "HelveticaNeue",
                textFontSize: 16,
                textColorHex: "#1c1c1e",
                headingTextFontName: "HelveticaNeue-Bold",
                headingTextFontSize: 24,
                headingTextColorHex: "#0a0a0a"
            ),
            toolbar: .init(
                textFontName: "AvenirNext-DemiBold",
                textFontSize: 17,
                textColorHex: "#ffffff",
                backgroundColorHex: "#007aff",
                headerText: "Secure Checkout",
                buttonText: "Cancel"
            ),
            textBox: .init(
                textFontName: "HelveticaNeue",
                textFontSize: 16,
                textColorHex: "#000000",
                borderWidth: 2,
                borderColorHex: "#e4e4e4",
                cornerRadius: 12
            ),
            view: .init(
                challengeViewBackgroundColorHex: "#ffffff",
                progressViewBackgroundColorHex: "#ffffff"
            ),
            buttons: [
                .submit: .init(textFontName: "AvenirNext-Bold", textFontSize: 16, textColorHex: "#ffffff", backgroundColorHex: "#ff3b30", cornerRadius: 18),
                .continue: .init(textFontSize: 16, textColorHex: "#ffffff", backgroundColorHex: "#007aff", cornerRadius: 14),
                .next: .init(textFontSize: 16, textColorHex: "#ffffff", backgroundColorHex: "#5ac8fa", cornerRadius: 12),
                .resend: .init(textFontSize: 14, textColorHex: "#000000", backgroundColorHex: "#bbdbff", cornerRadius: 10),
                .openOobApp: .init(textFontSize: 16, textColorHex: "#ffffff", backgroundColorHex: "#007aff", cornerRadius: 14),
                .addCardholder: .init(textFontSize: 14, textColorHex: "#000000", backgroundColorHex: "#bbdbff", cornerRadius: 10),
                .cancel: .init(textFontSize: 16, textColorHex: "#ffffff")
            ]
        )
        
        let dark = Gr4vyThreeDSUiCustomization(
            label: .init(
                textFontName: "HelveticaNeue",
                textFontSize: 16,
                textColorHex: "#ffffff",
                headingTextFontName: "HelveticaNeue-Bold",
                headingTextFontSize: 24,
                headingTextColorHex: "#ffffff"
            ),
            toolbar: .init(
                textFontName: "AvenirNext-DemiBold",
                textFontSize: 17,
                textColorHex: "#ffffff",
                backgroundColorHex: "#0a84ff",
                headerText: "SECURE CHECKOUT",
                buttonText: "Close"
            ),
            textBox: .init(
                textFontName: "HelveticaNeue",
                textFontSize: 16,
                textColorHex: "#ffffff",
                borderWidth: 2,
                borderColorHex: "#565a5c",
                cornerRadius: 12
            ),
            view: .init(
                challengeViewBackgroundColorHex: "#000000",
                progressViewBackgroundColorHex: "#000000"
            ),
            buttons: [
                .submit: .init(textFontName: "AvenirNext-Bold", textFontSize: 16, textColorHex: "#ffffff", backgroundColorHex: "#ff0a0a", cornerRadius: 18),
                .continue: .init(textFontSize: 16, textColorHex: "#ffffff", backgroundColorHex: "#0a84ff", cornerRadius: 14),
                .next: .init(textFontSize: 16, textColorHex: "#ffffff", backgroundColorHex: "#64d2ff", cornerRadius: 12),
                .resend: .init(textFontSize: 14, textColorHex: "#ffffff", backgroundColorHex: "#515154", cornerRadius: 10),
                .openOobApp: .init(textFontSize: 16, textColorHex: "#ffffff", backgroundColorHex: "#0a84ff", cornerRadius: 14),
                .addCardholder: .init(textFontSize: 14, textColorHex: "#ffffff", backgroundColorHex: "#515154", cornerRadius: 10),
                .cancel: .init(textFontSize: 16, textColorHex: "#ffffff")
            ]
        )
        
        return Gr4vyThreeDSUiCustomizationMap(default: light, dark: dark)
    }
    
    private func buildOrangePurpleTheme() -> Gr4vyThreeDSUiCustomizationMap {
        let light = Gr4vyThreeDSUiCustomization(
            label: .init(
                textFontName: "Georgia",
                textFontSize: 15,
                textColorHex: "#222222",
                headingTextFontName: "Georgia-Bold",
                headingTextFontSize: 26,
                headingTextColorHex: "#111111"
            ),
            toolbar: .init(
                textFontName: "AvenirNext-Heavy",
                textFontSize: 18,
                textColorHex: "#ffffff",
                backgroundColorHex: "#af52de",
                headerText: "Strong Auth",
                buttonText: "Dismiss"
            ),
            textBox: .init(
                textFontName: "Georgia",
                textFontSize: 16,
                textColorHex: "#000000",
                borderWidth: 3,
                borderColorHex: "#ff9500",
                cornerRadius: 20
            ),
            view: .init(
                challengeViewBackgroundColorHex: "#ffffff",
                progressViewBackgroundColorHex: "#ffffff"
            ),
            buttons: [
                .submit: .init(textFontName: "AvenirNext-Heavy", textFontSize: 15, textColorHex: "#ffffff", backgroundColorHex: "#ff9500", cornerRadius: 20),
                .continue: .init(textFontSize: 15, textColorHex: "#ffffff", backgroundColorHex: "#af52de", cornerRadius: 16),
                .next: .init(textFontSize: 15, textColorHex: "#ffffff", backgroundColorHex: "#bf5af2", cornerRadius: 14),
                .resend: .init(textFontSize: 13, textColorHex: "#000000", backgroundColorHex: "#f5e3ff", cornerRadius: 12),
                .openOobApp: .init(textFontSize: 15, textColorHex: "#ffffff", backgroundColorHex: "#af52de", cornerRadius: 16),
                .addCardholder: .init(textFontSize: 13, textColorHex: "#000000", backgroundColorHex: "#f5e3ff", cornerRadius: 12),
                .cancel: .init(textFontSize: 15, textColorHex: "#ffffff")
            ]
        )
        
        let dark = Gr4vyThreeDSUiCustomization(
            label: .init(
                textFontName: "Georgia",
                textFontSize: 15,
                textColorHex: "#ffffff",
                headingTextFontName: "Georgia-Bold",
                headingTextFontSize: 26,
                headingTextColorHex: "#ffffff"
            ),
            toolbar: .init(
                textFontName: "AvenirNext-Heavy",
                textFontSize: 18,
                textColorHex: "#ffffff",
                backgroundColorHex: "#6e32a8",
                headerText: "STRONG AUTH",
                buttonText: "Dismiss"
            ),
            textBox: .init(
                textFontName: "Georgia",
                textFontSize: 16,
                textColorHex: "#ffffff",
                borderWidth: 3,
                borderColorHex: "#ff9f0a",
                cornerRadius: 20
            ),
            view: .init(
                challengeViewBackgroundColorHex: "#000000",
                progressViewBackgroundColorHex: "#000000"
            ),
            buttons: [
                .submit: .init(textFontName: "AvenirNext-Heavy", textFontSize: 15, textColorHex: "#000000", backgroundColorHex: "#ff9f0a", cornerRadius: 20),
                .continue: .init(textFontSize: 15, textColorHex: "#000000", backgroundColorHex: "#bf5af2", cornerRadius: 16),
                .next: .init(textFontSize: 15, textColorHex: "#000000", backgroundColorHex: "#af52de", cornerRadius: 14),
                .resend: .init(textFontSize: 13, textColorHex: "#000000", backgroundColorHex: "#e6ccff", cornerRadius: 12),
                .openOobApp: .init(textFontSize: 15, textColorHex: "#000000", backgroundColorHex: "#bf5af2", cornerRadius: 16),
                .addCardholder: .init(textFontSize: 13, textColorHex: "#000000", backgroundColorHex: "#e6ccff", cornerRadius: 12),
                .cancel: .init(textFontSize: 15, textColorHex: "#ffffff")
            ]
        )
        
        return Gr4vyThreeDSUiCustomizationMap(default: light, dark: dark)
    }
    
    private func buildGreenYellowTheme() -> Gr4vyThreeDSUiCustomizationMap {
        let light = Gr4vyThreeDSUiCustomization(
            label: .init(
                textFontName: "AvenirNext-Regular",
                textFontSize: 16,
                textColorHex: "#1f1f1f",
                headingTextFontName: "AvenirNext-Bold",
                headingTextFontSize: 20,
                headingTextColorHex: "#111111"
            ),
            toolbar: .init(
                textFontName: "AvenirNext-Regular",
                textFontSize: 16,
                textColorHex: "#000000",
                backgroundColorHex: "#ffcc00",
                headerText: "3DS Challenge",
                buttonText: "Back"
            ),
            textBox: .init(
                textFontName: "AvenirNext-Regular",
                textFontSize: 16,
                textColorHex: "#000000",
                borderWidth: 4,
                borderColorHex: "#34c759",
                cornerRadius: 6
            ),
            view: .init(
                challengeViewBackgroundColorHex: "#ffffff",
                progressViewBackgroundColorHex: "#f8f8f8"
            ),
            buttons: [
                .submit: .init(textFontName: "AvenirNext-Bold", textFontSize: 17, textColorHex: "#ffffff", backgroundColorHex: "#34c759", cornerRadius: 8),
                .continue: .init(textFontSize: 16, textColorHex: "#000000", backgroundColorHex: "#ffcc00", cornerRadius: 8),
                .next: .init(textFontSize: 15, textColorHex: "#000000", backgroundColorHex: "#ffe066", cornerRadius: 8),
                .resend: .init(textFontSize: 13, textColorHex: "#000000", backgroundColorHex: "#e7ffd6", cornerRadius: 6),
                .openOobApp: .init(textFontSize: 16, textColorHex: "#ffffff", backgroundColorHex: "#34c759", cornerRadius: 8),
                .addCardholder: .init(textFontSize: 13, textColorHex: "#000000", backgroundColorHex: "#e7ffd6", cornerRadius: 6),
                .cancel: .init(textFontSize: 16, textColorHex: "#000000")
            ]
        )
        
        let dark = Gr4vyThreeDSUiCustomization(
            label: .init(
                textFontName: "AvenirNext-Regular",
                textFontSize: 16,
                textColorHex: "#ffffff",
                headingTextFontName: "AvenirNext-Bold",
                headingTextFontSize: 20,
                headingTextColorHex: "#ffffff"
            ),
            toolbar: .init(
                textFontName: "AvenirNext-Regular",
                textFontSize: 16,
                textColorHex: "#000000",
                backgroundColorHex: "#ffd60a",
                headerText: "3DS CHALLENGE",
                buttonText: "Back"
            ),
            textBox: .init(
                textFontName: "AvenirNext-Regular",
                textFontSize: 16,
                textColorHex: "#ffffff",
                borderWidth: 4,
                borderColorHex: "#30d158",
                cornerRadius: 6
            ),
            view: .init(
                challengeViewBackgroundColorHex: "#000000",
                progressViewBackgroundColorHex: "#000000"
            ),
            buttons: [
                .submit: .init(textFontName: "AvenirNext-Bold", textFontSize: 17, textColorHex: "#000000", backgroundColorHex: "#30d158", cornerRadius: 8),
                .continue: .init(textFontSize: 16, textColorHex: "#000000", backgroundColorHex: "#ffd60a", cornerRadius: 8),
                .next: .init(textFontSize: 15, textColorHex: "#000000", backgroundColorHex: "#ffe066", cornerRadius: 8),
                .resend: .init(textFontSize: 13, textColorHex: "#000000", backgroundColorHex: "#2e2e2e", cornerRadius: 6),
                .openOobApp: .init(textFontSize: 16, textColorHex: "#000000", backgroundColorHex: "#30d158", cornerRadius: 8),
                .addCardholder: .init(textFontSize: 13, textColorHex: "#000000", backgroundColorHex: "#2e2e2e", cornerRadius: 6),
                .cancel: .init(textFontSize: 16, textColorHex: "#000000")
            ]
        )
        
        return Gr4vyThreeDSUiCustomizationMap(default: light, dark: dark)
    }
}

// MARK: - Custom TextField Cell
class FieldsTextFieldTableViewCell: UITableViewCell {
    
    private var textField: UITextField?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Remove the old text field before reusing
        textField?.removeFromSuperview()
        textField = nil
    }
    
    private func setupUI() {
        selectionStyle = .none
    }
    
    func configure(with textField: UITextField) {
        // Remove any existing text field
        self.textField?.removeFromSuperview()
        
        self.textField = textField
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
}

// MARK: - Custom Switch Cell
class SwitchTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private var switchControl: UISwitch?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Remove the old switch before reusing
        switchControl?.removeFromSuperview()
        switchControl = nil
    }
    
    private func setupUI() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
        
        selectionStyle = .none
    }
    
    func configure(with switchControl: UISwitch, title: String) {
        // Remove any existing switch
        self.switchControl?.removeFromSuperview()
        
        self.switchControl = switchControl
        titleLabel.text = title
        
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(switchControl)
        
        NSLayoutConstraint.activate([
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            switchControl.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
    }
}

// MARK: - Custom Segmented Control Cell
class FieldsSegmentedControlTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private var segmentedControl: UISegmentedControl?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Remove the old segmented control before reusing
        segmentedControl?.removeFromSuperview()
        segmentedControl = nil
        titleLabel.text = nil
    }
    
    private func setupUI() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel
        contentView.addSubview(titleLabel)
        
        selectionStyle = .none
    }
    
    func configure(with segmentedControl: UISegmentedControl, title: String) {
        // Remove any existing segmented control
        self.segmentedControl?.removeFromSuperview()
        
        self.segmentedControl = segmentedControl
        titleLabel.text = title.isEmpty ? nil : title
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentedControl)
        
        if title.isEmpty {
            // No title, just center the segmented control
            titleLabel.isHidden = true
            NSLayoutConstraint.activate([
                segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                segmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                segmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
                segmentedControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 32)
            ])
        } else {
            // Show title above segmented control
            titleLabel.isHidden = false
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                
                segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
                segmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
                segmentedControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 32)
            ])
        }
    }
}

// MARK: - Custom Button Cell
class ButtonTableViewCell: UITableViewCell {
    
    private let button = UIButton(type: .system)
    private var action: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        contentView.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        selectionStyle = .none
    }
    
    func configure(title: String, color: UIColor, action: @escaping () -> Void) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        self.action = action
    }
    
    @objc private func buttonTapped() {
        action?()
    }
}

