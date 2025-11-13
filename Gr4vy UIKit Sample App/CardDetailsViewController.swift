//
//  CardDetailsViewController.swift
//  Gr4vy UIKit Sample App
//
//  Created by Gr4vy
//

import UIKit
import gr4vy_swift

class CardDetailsViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = UIView()
    private let errorLabel = UILabel()
    
    // Form fields
    private let currencyTextField = UITextField()
    private let amountTextField = UITextField()
    private let binTextField = UITextField()
    private let countryTextField = UITextField()
    private let intentTextField = UITextField()
    private let isSubsequentPaymentSwitch = UISwitch()
    private let merchantInitiatedSwitch = UISwitch()
    private let metadataTextField = UITextField()
    private let paymentMethodIdTextField = UITextField()
    private let paymentSourceTextField = UITextField()
    
    // Picker data
    private let intentOptions = ["", "authorize", "capture"]
    private let paymentSourceOptions = ["", "ecommerce", "moto", "recurring", "installment", "card_on_file"]
    
    // State
    private var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupErrorView()
        loadSavedData()
    }
    
    private func setupUI() {
        title = "Card Details"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Add GET button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "GET",
            style: .done,
            target: self,
            action: #selector(getButtonTapped)
        )
        
        // Configure table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(FieldsSwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        
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
        // Currency field (required)
        currencyTextField.placeholder = "currency"
        currencyTextField.autocapitalizationType = .none
        currencyTextField.autocorrectionType = .no
        currencyTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Amount field
        amountTextField.placeholder = "amount"
        amountTextField.keyboardType = .numberPad
        amountTextField.autocapitalizationType = .none
        amountTextField.autocorrectionType = .no
        amountTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // BIN field (max 8 characters)
        binTextField.placeholder = "bin"
        binTextField.keyboardType = .numberPad
        binTextField.autocapitalizationType = .none
        binTextField.autocorrectionType = .no
        binTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Country field (max 2 characters)
        countryTextField.placeholder = "country"
        countryTextField.autocapitalizationType = .none
        countryTextField.autocorrectionType = .no
        countryTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Intent field with picker
        intentTextField.placeholder = "intent"
        intentTextField.autocapitalizationType = .none
        intentTextField.autocorrectionType = .no
        setupPickerForTextField(intentTextField, options: intentOptions)
        
        // Metadata field
        metadataTextField.placeholder = "metadata"
        metadataTextField.autocapitalizationType = .none
        metadataTextField.autocorrectionType = .no
        metadataTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Payment Method ID field
        paymentMethodIdTextField.placeholder = "payment_method_id"
        paymentMethodIdTextField.autocapitalizationType = .none
        paymentMethodIdTextField.autocorrectionType = .no
        paymentMethodIdTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Payment Source field with picker
        paymentSourceTextField.placeholder = "payment_source"
        paymentSourceTextField.autocapitalizationType = .none
        paymentSourceTextField.autocorrectionType = .no
        setupPickerForTextField(paymentSourceTextField, options: paymentSourceOptions)
        
        // Switches
        isSubsequentPaymentSwitch.addTarget(self, action: #selector(switchDidChange(_:)), for: .valueChanged)
        merchantInitiatedSwitch.addTarget(self, action: #selector(switchDidChange(_:)), for: .valueChanged)
    }
    
    private func setupPickerForTextField(_ textField: UITextField, options: [String]) {
        let pickerView = UIPickerView()
        pickerView.tag = textField == intentTextField ? 1 : 2
        pickerView.delegate = self
        pickerView.dataSource = self
        textField.inputView = pickerView
        
        // Add toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPicker))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
    }
    
    @objc private func dismissPicker() {
        view.endEditing(true)
    }
    
    private func loadSavedData() {
        currencyTextField.text = UserDefaults.standard.string(forKey: "card_details_currency") ?? ""
        amountTextField.text = UserDefaults.standard.string(forKey: "card_details_amount") ?? ""
        binTextField.text = UserDefaults.standard.string(forKey: "card_details_bin") ?? ""
        countryTextField.text = UserDefaults.standard.string(forKey: "card_details_country") ?? ""
        intentTextField.text = UserDefaults.standard.string(forKey: "card_details_intent") ?? ""
        isSubsequentPaymentSwitch.isOn = UserDefaults.standard.bool(forKey: "card_details_is_subsequent_payment")
        merchantInitiatedSwitch.isOn = UserDefaults.standard.bool(forKey: "card_details_merchant_initiated")
        metadataTextField.text = UserDefaults.standard.string(forKey: "card_details_metadata") ?? ""
        paymentMethodIdTextField.text = UserDefaults.standard.string(forKey: "card_details_payment_method_id") ?? ""
        paymentSourceTextField.text = UserDefaults.standard.string(forKey: "card_details_payment_source") ?? ""
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let value = textField.text ?? ""
        
        // Apply character limits
        if textField == binTextField && value.count > 8 {
            textField.text = String(value.prefix(8))
            return
        }
        
        if textField == countryTextField && value.count > 2 {
            textField.text = String(value.prefix(2))
            return
        }
        
        // Save to UserDefaults
        switch textField {
        case currencyTextField:
            UserDefaults.standard.set(value, forKey: "card_details_currency")
        case amountTextField:
            UserDefaults.standard.set(value, forKey: "card_details_amount")
        case binTextField:
            UserDefaults.standard.set(value, forKey: "card_details_bin")
        case countryTextField:
            UserDefaults.standard.set(value, forKey: "card_details_country")
        case metadataTextField:
            UserDefaults.standard.set(value, forKey: "card_details_metadata")
        case paymentMethodIdTextField:
            UserDefaults.standard.set(value, forKey: "card_details_payment_method_id")
        default:
            break
        }
    }
    
    @objc private func switchDidChange(_ switch: UISwitch) {
        switch `switch` {
        case isSubsequentPaymentSwitch:
            UserDefaults.standard.set(`switch`.isOn, forKey: "card_details_is_subsequent_payment")
        case merchantInitiatedSwitch:
            UserDefaults.standard.set(`switch`.isOn, forKey: "card_details_merchant_initiated")
        default:
            break
        }
    }
    
    @objc private func getButtonTapped() {
        sendRequest()
    }
    
    private func sendRequest() {
        // Validate required fields
        let trimmedCurrency = currencyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedCurrency.isEmpty else {
            showError("Please enter a currency")
            return
        }
        
        isLoading = true
        errorView.isHidden = true
        activityIndicator.startAnimating()
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        // Get admin settings
        let gr4vyID = UserDefaults.standard.string(forKey: "gr4vyId")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let token = UserDefaults.standard.string(forKey: "apiToken")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let serverEnvironment = UserDefaults.standard.string(forKey: "serverEnvironment") ?? "sandbox"
        let timeoutString = UserDefaults.standard.string(forKey: "timeout") ?? ""
        
        guard !gr4vyID.isEmpty else {
            showError("Please configure Gr4vy ID in Admin settings")
            return
        }
        
        guard !token.isEmpty else {
            showError("Please configure API Token in Admin settings")
            return
        }
        
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
                timeout: timeoutInterval
            )
        } else {
            gr4vy = try? Gr4vy(
                gr4vyId: gr4vyID,
                token: token,
                server: server
            )
        }
        
        guard let gr4vy = gr4vy else {
            showError("Failed to configure Gr4vy SDK")
            return
        }
        
        // Prepare all field values
        let amount = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let bin = binTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let country = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let intent = intentTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let metadata = metadataTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let paymentMethodId = paymentMethodIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let paymentSource = paymentSourceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let cardDetails = Gr4vyCardDetails(
            currency: trimmedCurrency,
            amount: amount?.isEmpty == true ? nil : amount,
            bin: bin?.isEmpty == true ? nil : bin,
            country: country?.isEmpty == true ? nil : country,
            intent: intent?.isEmpty == true ? nil : intent,
            isSubsequentPayment: isSubsequentPaymentSwitch.isOn ? true : nil,
            merchantInitiated: merchantInitiatedSwitch.isOn ? true : nil,
            metadata: metadata?.isEmpty == true ? nil : metadata,
            paymentMethodId: paymentMethodId?.isEmpty == true ? nil : paymentMethodId,
            paymentSource: paymentSource?.isEmpty == true ? nil : paymentSource
        )
        
        let requestBody = Gr4vyCardDetailsRequest(cardDetails: cardDetails)
        
        gr4vy.cardDetails.get(request: requestBody) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                
                switch result {
                case .success(let cardDetails):
                    // Convert the response to JSON for display
                    do {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        let jsonData = try encoder.encode(cardDetails)
                        
                        let responseVC = JSONResponseViewController()
                        responseVC.responseData = jsonData
                        self?.navigationController?.pushViewController(responseVC, animated: true)
                    } catch {
                        self?.showError("Failed to encode response: \(error.localizedDescription)")
                    }
                    
                case .failure(let error):
                    self?.handleError(error, gr4vyID: gr4vyID)
                }
            }
        }
    }
    
    private func handleError(_ error: Error, gr4vyID: String) {
        if let gr4vyError = error as? Gr4vyError {
            switch gr4vyError {
            case .invalidGr4vyId:
                showError("Invalid Gr4vy ID: \(gr4vyError.localizedDescription)")
            case .badURL(let url):
                showError("Bad URL: \(url)")
            case .httpError(let statusCode, let responseData, let message):
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
            case .uiContextError(let message):
                showError("UI error: \(message)")
            case .threeDSError(let message):
                showError("3DS error: \(message)")
            }
        } else {
            handleNetworkError(error, gr4vyID: gr4vyID)
        }
    }
    
    private func handleNetworkError(_ error: Error, gr4vyID: String) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotFindHost:
                showError("Cannot find server. Please check your Merchant ID (\(gr4vyID)). The URL being called is: https://api.\(gr4vyID).gr4vy.app/card-details")
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
            showError("Failed to get card details: \(error.localizedDescription)")
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
extension CardDetailsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 { // Intent picker
            return intentOptions.count
        } else { // Payment source picker
            return paymentSourceOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 { // Intent picker
            return intentOptions[row]
        } else { // Payment source picker
            return paymentSourceOptions[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 { // Intent picker
            let selectedValue = intentOptions[row]
            intentTextField.text = selectedValue
            UserDefaults.standard.set(selectedValue, forKey: "card_details_intent")
        } else { // Payment source picker
            let selectedValue = paymentSourceOptions[row]
            paymentSourceTextField.text = selectedValue
            UserDefaults.standard.set(selectedValue, forKey: "card_details_payment_source")
        }
    }
}

// MARK: - TableView DataSource and Delegate
extension CardDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 5 // currency, amount, bin, country, intent
        case 1: return 2 // is_subsequent_payment, merchant_initiated switches
        case 2: return 3 // metadata, payment_method_id, payment_source
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Basic Information"
        case 1: return "Options"
        case 2: return "Additional Fields"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
            switch indexPath.row {
            case 0:
                cell.configure(with: currencyTextField)
            case 1:
                cell.configure(with: amountTextField)
            case 2:
                cell.configure(with: binTextField)
            case 3:
                cell.configure(with: countryTextField)
            case 4:
                cell.configure(with: intentTextField)
            default:
                break
            }
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! FieldsSwitchTableViewCell
            switch indexPath.row {
            case 0:
                cell.configure(with: isSubsequentPaymentSwitch, title: "is_subsequent_payment")
            case 1:
                cell.configure(with: merchantInitiatedSwitch, title: "merchant_initiated")
            default:
                break
            }
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
            switch indexPath.row {
            case 0:
                cell.configure(with: metadataTextField)
            case 1:
                cell.configure(with: paymentMethodIdTextField)
            case 2:
                cell.configure(with: paymentSourceTextField)
            default:
                break
            }
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - Custom Switch Cell
class FieldsSwitchTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private var switchControl: UISwitch?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
    
    func configure(with switchControl: UISwitch, title: String) {
        self.switchControl = switchControl
        titleLabel.text = title
        
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(switchControl)
        
        NSLayoutConstraint.activate([
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            switchControl.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
        
        selectionStyle = .none
    }
}

// MARK: - Custom TextField Cell
class TextFieldTableViewCell: UITableViewCell {
    
    private var textField: UITextField?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
    }
    
    func configure(with textField: UITextField) {
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
