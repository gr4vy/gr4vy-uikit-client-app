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
    private let cardNumberTextField = UITextField()
    private let intentTextField = UITextField()
    private let subsequentPaymentsSwitch = UISwitch()
    private let merchantInitiatedSwitch = UISwitch()
    
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
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        
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
        cardNumberTextField.placeholder = "card_number"
        cardNumberTextField.keyboardType = .numberPad
        cardNumberTextField.autocapitalizationType = .none
        cardNumberTextField.autocorrectionType = .no
        cardNumberTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        intentTextField.placeholder = "intent"
        intentTextField.autocapitalizationType = .none
        intentTextField.autocorrectionType = .no
        intentTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        subsequentPaymentsSwitch.addTarget(self, action: #selector(switchDidChange(_:)), for: .valueChanged)
        merchantInitiatedSwitch.addTarget(self, action: #selector(switchDidChange(_:)), for: .valueChanged)
    }
    
    private func loadSavedData() {
        cardNumberTextField.text = UserDefaults.standard.string(forKey: "card_details_card_number") ?? ""
        intentTextField.text = UserDefaults.standard.string(forKey: "card_details_intent") ?? ""
        subsequentPaymentsSwitch.isOn = UserDefaults.standard.bool(forKey: "card_details_subsequent_payments")
        merchantInitiatedSwitch.isOn = UserDefaults.standard.bool(forKey: "card_details_merchant_initiated")
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let value = textField.text ?? ""
        
        switch textField {
        case cardNumberTextField:
            UserDefaults.standard.set(value, forKey: "card_details_card_number")
        case intentTextField:
            UserDefaults.standard.set(value, forKey: "card_details_intent")
        default:
            break
        }
    }
    
    @objc private func switchDidChange(_ switch: UISwitch) {
        switch `switch` {
        case subsequentPaymentsSwitch:
            UserDefaults.standard.set(`switch`.isOn, forKey: "card_details_subsequent_payments")
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
        
        let cardNumber = cardNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let intent = intentTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let cardDetails = Gr4vyCardDetails(
            currency: "USD",
            bin: cardNumber,
            intent: intent?.isEmpty == true ? nil : intent,
            isSubsequentPayment: subsequentPaymentsSwitch.isOn,
            merchantInitiated: merchantInitiatedSwitch.isOn
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

// MARK: - TableView DataSource and Delegate
extension CardDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // card_number, intent
        case 1: return 2 // subsequent_payments, merchant_initiated switches
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Card Information"
        case 1: return "Options"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
            switch indexPath.row {
            case 0:
                cell.configure(with: cardNumberTextField)
            case 1:
                cell.configure(with: intentTextField)
            default:
                break
            }
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
            switch indexPath.row {
            case 0:
                cell.configure(with: subsequentPaymentsSwitch, title: "subsequent_payments")
            case 1:
                cell.configure(with: merchantInitiatedSwitch, title: "merchant_initiated")
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
