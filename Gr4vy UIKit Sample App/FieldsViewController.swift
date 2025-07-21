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
    case clickToPay = "click_to_pay"
    case id = "id"
    
    var displayName: String {
        switch self {
        case .card: return "Card"
        case .clickToPay: return "Click to Pay"
        case .id: return "ID"
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
    
    // Click to Pay fields
    private let merchantTransactionIdTextField = UITextField()
    private let srcCorrelationIdTextField = UITextField()
    
    // ID fields
    private let paymentMethodIdTextField = UITextField()
    private let idSecurityCodeTextField = UITextField()
    
    // State
    private var isLoading = false
    private var selectedPaymentMethodType: PaymentMethodType = .card
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupErrorView()
        loadSavedData()
    }
    
    private func setupUI() {
        title = "Fields"
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
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(SegmentedControlTableViewCell.self, forCellReuseIdentifier: "SegmentedControlCell")
        
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
        
        // Click to Pay fields
        merchantTransactionIdTextField.placeholder = "merchant_transaction_id"
        merchantTransactionIdTextField.autocapitalizationType = .none
        merchantTransactionIdTextField.autocorrectionType = .no
        merchantTransactionIdTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        srcCorrelationIdTextField.placeholder = "src_correlation_id"
        srcCorrelationIdTextField.autocapitalizationType = .none
        srcCorrelationIdTextField.autocorrectionType = .no
        srcCorrelationIdTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
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
    }
    
    private func loadSavedData() {
        checkoutSessionIdTextField.text = UserDefaults.standard.string(forKey: "fields_checkout_session_id") ?? ""
        
        let savedPaymentMethodType = UserDefaults.standard.string(forKey: "fields_payment_method_type") ?? PaymentMethodType.card.rawValue
        if let paymentMethodType = PaymentMethodType(rawValue: savedPaymentMethodType) {
            selectedPaymentMethodType = paymentMethodType
            paymentMethodSegmentedControl.selectedSegmentIndex = PaymentMethodType.allCases.firstIndex(of: paymentMethodType) ?? 0
        }
        
        // Card fields
        cardNumberTextField.text = UserDefaults.standard.string(forKey: "fields_card_number") ?? ""
        expirationDateTextField.text = UserDefaults.standard.string(forKey: "fields_expiration_date") ?? ""
        securityCodeTextField.text = UserDefaults.standard.string(forKey: "fields_security_code") ?? ""
        
        // Click to Pay fields
        merchantTransactionIdTextField.text = UserDefaults.standard.string(forKey: "fields_merchant_transaction_id") ?? ""
        srcCorrelationIdTextField.text = UserDefaults.standard.string(forKey: "fields_src_correlation_id") ?? ""
        
        // ID fields
        paymentMethodIdTextField.text = UserDefaults.standard.string(forKey: "fields_payment_method_id") ?? ""
        idSecurityCodeTextField.text = UserDefaults.standard.string(forKey: "fields_id_security_code") ?? ""
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let value = textField.text ?? ""
        
        switch textField {
        case checkoutSessionIdTextField:
            UserDefaults.standard.set(value, forKey: "fields_checkout_session_id")
        case cardNumberTextField:
            UserDefaults.standard.set(value, forKey: "fields_card_number")
        case expirationDateTextField:
            UserDefaults.standard.set(value, forKey: "fields_expiration_date")
        case securityCodeTextField:
            UserDefaults.standard.set(value, forKey: "fields_security_code")
        case merchantTransactionIdTextField:
            UserDefaults.standard.set(value, forKey: "fields_merchant_transaction_id")
        case srcCorrelationIdTextField:
            UserDefaults.standard.set(value, forKey: "fields_src_correlation_id")
        case paymentMethodIdTextField:
            UserDefaults.standard.set(value, forKey: "fields_payment_method_id")
        case idSecurityCodeTextField:
            UserDefaults.standard.set(value, forKey: "fields_id_security_code")
        default:
            break
        }
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
        let timeoutInterval = TimeInterval(Double(timeoutString) ?? 30.0)
        
        guard let gr4vy = try? Gr4vy(
            gr4vyId: gr4vyID,
            token: token,
            server: server,
            timeout: timeoutInterval
        ) else {
            showError("Failed to configure Gr4vy SDK")
            return
        }
        
        let checkoutSessionId = checkoutSessionIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Prepare payment method based on selected type
        let paymentMethod: Gr4vyPaymentMethod
        
        switch selectedPaymentMethodType {
        case .card:
            let number = cardNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let expirationDate = expirationDateTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let securityCode = securityCodeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            let cardMethod = CardPaymentMethod(
                number: number,
                expirationDate: expirationDate,
                securityCode: securityCode.isEmpty ? nil : securityCode
            )
            paymentMethod = .card(cardMethod)
            
        case .clickToPay:
            let merchantTransactionId = merchantTransactionIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let srcCorrelationId = srcCorrelationIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            let clickToPayMethod = ClickToPayPaymentMethod(
                merchantTransactionId: merchantTransactionId,
                srcCorrelationId: srcCorrelationId
            )
            paymentMethod = .clickToPay(clickToPayMethod)
            
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
        
        gr4vy.tokenize(checkoutSessionId: checkoutSessionId, cardData: cardData) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                
                switch result {
                case .success(let options):
                    // Handle 204 No Content response - tokenization successful
                    let successResponse = [
                        "status": "success",
                        "message": "Payment method tokenized successfully",
                        "method": "tokenize",
                        "timestamp": ISO8601DateFormatter().string(from: Date()),
                        "details": "The payment method has been securely tokenized and stored"
                    ]
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: successResponse, options: .prettyPrinted)
                        
                        let responseVC = JSONResponseViewController()
                        responseVC.responseData = jsonData
                        self?.navigationController?.pushViewController(responseVC, animated: true)
                    } catch {
                        self?.showError("Success, but failed to format response: \(error.localizedDescription)")
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

// MARK: - TableView DataSource and Delegate
extension FieldsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // checkout session id
        case 1: return 1 // payment method type
        case 2:
            switch selectedPaymentMethodType {
            case .card: return 3 // number, expiration_date, security_code
            case .clickToPay: return 2 // merchant_transaction_id, src_correlation_id
            case .id: return 2 // payment_method_id, security_code
            }
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Session"
        case 1: return "Payment Method Type"
        case 2:
            switch selectedPaymentMethodType {
            case .card: return "Card Details"
            case .clickToPay: return "Click to Pay"
            case .id: return "Payment Method ID"
            }
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
            cell.configure(with: checkoutSessionIdTextField)
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlCell", for: indexPath) as! SegmentedControlTableViewCell
            cell.configure(with: paymentMethodSegmentedControl, title: "Payment Method Type")
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
            
            switch selectedPaymentMethodType {
            case .card:
                switch indexPath.row {
                case 0: cell.configure(with: cardNumberTextField)
                case 1: cell.configure(with: expirationDateTextField)
                case 2: cell.configure(with: securityCodeTextField)
                default: break
                }
            case .clickToPay:
                switch indexPath.row {
                case 0: cell.configure(with: merchantTransactionIdTextField)
                case 1: cell.configure(with: srcCorrelationIdTextField)
                default: break
                }
            case .id:
                switch indexPath.row {
                case 0: cell.configure(with: paymentMethodIdTextField)
                case 1: cell.configure(with: idSecurityCodeTextField)
                default: break
                }
            }
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }
} 