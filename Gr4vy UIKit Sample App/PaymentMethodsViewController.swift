//
//  PaymentMethodsViewController.swift
//  Gr4vy UIKit Sample App
//
//  Created by Gr4vy
//

import UIKit
import gr4vy_swift

class PaymentMethodsViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = UIView()
    private let errorLabel = UILabel()
    
    // Form fields
    private let buyerIdTextField = UITextField()
    private let externalIdentifierTextField = UITextField()
    private let limitTextField = UITextField()
    private let sortTextField = UITextField()
    private let createdAfterTextField = UITextField()
    private let createdBeforeTextField = UITextField()
    
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
        title = "Payment Methods"
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
        buyerIdTextField.placeholder = "buyer_id"
        buyerIdTextField.autocapitalizationType = .none
        buyerIdTextField.autocorrectionType = .no
        buyerIdTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        externalIdentifierTextField.placeholder = "external_identifier"
        externalIdentifierTextField.autocapitalizationType = .none
        externalIdentifierTextField.autocorrectionType = .no
        externalIdentifierTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        limitTextField.placeholder = "limit"
        limitTextField.keyboardType = .numberPad
        limitTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        sortTextField.placeholder = "sort"
        sortTextField.autocapitalizationType = .none
        sortTextField.autocorrectionType = .no
        sortTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        createdAfterTextField.placeholder = "created_after (YYYY-MM-DD)"
        createdAfterTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        createdBeforeTextField.placeholder = "created_before (YYYY-MM-DD)"
        createdBeforeTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func loadSavedData() {
        buyerIdTextField.text = UserDefaults.standard.string(forKey: "payment_methods_buyer_id") ?? ""
        externalIdentifierTextField.text = UserDefaults.standard.string(forKey: "payment_methods_external_identifier") ?? ""
        limitTextField.text = UserDefaults.standard.string(forKey: "payment_methods_limit") ?? ""
        sortTextField.text = UserDefaults.standard.string(forKey: "payment_methods_sort") ?? ""
        createdAfterTextField.text = UserDefaults.standard.string(forKey: "payment_methods_created_after") ?? ""
        createdBeforeTextField.text = UserDefaults.standard.string(forKey: "payment_methods_created_before") ?? ""
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let value = textField.text ?? ""
        
        switch textField {
        case buyerIdTextField:
            UserDefaults.standard.set(value, forKey: "payment_methods_buyer_id")
        case externalIdentifierTextField:
            UserDefaults.standard.set(value, forKey: "payment_methods_external_identifier")
        case limitTextField:
            UserDefaults.standard.set(value, forKey: "payment_methods_limit")
        case sortTextField:
            UserDefaults.standard.set(value, forKey: "payment_methods_sort")
        case createdAfterTextField:
            UserDefaults.standard.set(value, forKey: "payment_methods_created_after")
        case createdBeforeTextField:
            UserDefaults.standard.set(value, forKey: "payment_methods_created_before")
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
        
        let buyerId = buyerIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let externalIdentifier = externalIdentifierTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let limit = limitTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sort = sortTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let createdAfter = createdAfterTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let createdBefore = createdBeforeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create date formatter for date parsing
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var createdAfterDate: Date?
        var createdBeforeDate: Date?
        
        if let createdAfter = createdAfter, !createdAfter.isEmpty {
            createdAfterDate = dateFormatter.date(from: createdAfter)
        }
        
        if let createdBefore = createdBefore, !createdBefore.isEmpty {
            createdBeforeDate = dateFormatter.date(from: createdBefore)
        }
        
        let paymentMethods = Gr4vyBuyersPaymentMethods(
            buyerId: buyerId.isEmpty ? nil : buyerId,
            buyerExternalIdentifier: externalIdentifier?.isEmpty == false ? externalIdentifier : nil,
            sortBy: nil, // Not implemented in this form - would need Gr4vySortBy enum  
            orderBy: Gr4vyOrderBy(rawValue: "desc"), // Default value
            country: nil, // Not implemented in this form
            currency: nil // Not implemented in this form
        )
        
        let requestBody = Gr4vyBuyersPaymentMethodsRequest(
            paymentMethods: paymentMethods
        )
        
        gr4vy.paymentMethods.list(request: requestBody) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                
                switch result {
                case .success(let paymentMethods):
                    // Convert the response to JSON for display
                    do {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        let jsonData = try encoder.encode(paymentMethods)
                        
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
                showError("Cannot find server. Please check your Merchant ID (\(gr4vyID)). The URL being called is: https://api.\(gr4vyID).gr4vy.app/buyers/{buyer_id}/payment-methods")
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
            showError("Failed to get payment methods: \(error.localizedDescription)")
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
extension PaymentMethodsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // buyer_id, external_identifier
        case 1: return 4 // limit, sort, created_after, created_before
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Buyer Identification"
        case 1: return "Filtering & Sorting"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.configure(with: buyerIdTextField)
            case 1:
                cell.configure(with: externalIdentifierTextField)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(with: limitTextField)
            case 1:
                cell.configure(with: sortTextField)
            case 2:
                cell.configure(with: createdAfterTextField)
            case 3:
                cell.configure(with: createdBeforeTextField)
            default:
                break
            }
        default:
            break
        }
        
        return cell
    }
} 
