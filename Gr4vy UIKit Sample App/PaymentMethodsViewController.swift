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
    private let buyerExternalIdentifierTextField = UITextField()
    private let sortByTextField = UITextField()
    private let orderByTextField = UITextField()
    private let countryTextField = UITextField()
    private let currencyTextField = UITextField()
    
    // Picker data
    private var sortByOptions: [Gr4vySortBy?] = [nil] + Gr4vySortBy.allCases
    private let orderByOptions = ["desc", "asc"]
    
    // State
    private var isLoading = false
    private var selectedSortBy: Gr4vySortBy?
    private var selectedOrderBy: String = "desc"
    
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
        tableView.register(PaymentMethodsTextFieldTableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
        
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
        
        buyerExternalIdentifierTextField.placeholder = "buyer_external_identifier"
        buyerExternalIdentifierTextField.autocapitalizationType = .none
        buyerExternalIdentifierTextField.autocorrectionType = .no
        buyerExternalIdentifierTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Sort By field with picker
        sortByTextField.placeholder = "sort_by"
        sortByTextField.autocapitalizationType = .none
        sortByTextField.autocorrectionType = .no
        setupPickerForTextField(sortByTextField, tag: 1)
        
        // Order By field with picker
        orderByTextField.placeholder = "order_by"
        orderByTextField.autocapitalizationType = .none
        orderByTextField.autocorrectionType = .no
        setupPickerForTextField(orderByTextField, tag: 2)
        
        countryTextField.placeholder = "country"
        countryTextField.autocapitalizationType = .none
        countryTextField.autocorrectionType = .no
        countryTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        currencyTextField.placeholder = "currency"
        currencyTextField.autocapitalizationType = .none
        currencyTextField.autocorrectionType = .no
        currencyTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func setupPickerForTextField(_ textField: UITextField, tag: Int) {
        let pickerView = UIPickerView()
        pickerView.tag = tag
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
        buyerIdTextField.text = UserDefaults.standard.string(forKey: "payment_methods_buyer_id") ?? ""
        buyerExternalIdentifierTextField.text = UserDefaults.standard.string(forKey: "payment_methods_buyer_external_identifier") ?? ""
        
        // Load sort_by
        if let sortByRawValue = UserDefaults.standard.string(forKey: "payment_methods_sort_by") {
            selectedSortBy = Gr4vySortBy(rawValue: sortByRawValue)
            sortByTextField.text = selectedSortBy?.rawValue ?? ""
        } else {
            selectedSortBy = nil
            sortByTextField.text = "None"
        }
        
        // Load order_by
        selectedOrderBy = UserDefaults.standard.string(forKey: "payment_methods_order_by") ?? "desc"
        orderByTextField.text = selectedOrderBy
        
        countryTextField.text = UserDefaults.standard.string(forKey: "payment_methods_country") ?? ""
        currencyTextField.text = UserDefaults.standard.string(forKey: "payment_methods_currency") ?? ""
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let value = textField.text ?? ""
        
        switch textField {
        case buyerIdTextField:
            UserDefaults.standard.set(value.isEmpty ? nil : value, forKey: "payment_methods_buyer_id")
        case buyerExternalIdentifierTextField:
            UserDefaults.standard.set(value.isEmpty ? nil : value, forKey: "payment_methods_buyer_external_identifier")
        case countryTextField:
            UserDefaults.standard.set(value.isEmpty ? nil : value, forKey: "payment_methods_country")
        case currencyTextField:
            UserDefaults.standard.set(value.isEmpty ? nil : value, forKey: "payment_methods_currency")
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
        
        // Prepare field values
        let buyerId = buyerIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let buyerExtId = buyerExternalIdentifierTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let countryVal = countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let currencyVal = currencyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let paymentMethods = Gr4vyBuyersPaymentMethods(
            buyerId: buyerId?.isEmpty == false ? buyerId : nil,
            buyerExternalIdentifier: buyerExtId?.isEmpty == false ? buyerExtId : nil,
            sortBy: selectedSortBy,
            orderBy: Gr4vyOrderBy(rawValue: selectedOrderBy),
            country: countryVal?.isEmpty == false ? countryVal : nil,
            currency: currencyVal?.isEmpty == false ? currencyVal : nil
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
                showError("Cannot find server. Please check your Merchant ID (\(gr4vyID)). The URL being called is: https://api.\(gr4vyID).gr4vy.app/payment-methods")
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

// MARK: - UIPickerView DataSource and Delegate
extension PaymentMethodsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 { // Sort By picker
            return sortByOptions.count
        } else { // Order By picker
            return orderByOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 { // Sort By picker
            if let sortBy = sortByOptions[row] {
                return sortBy.rawValue
            } else {
                return "None"
            }
        } else { // Order By picker
            return orderByOptions[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 { // Sort By picker
            selectedSortBy = sortByOptions[row]
            if let sortBy = selectedSortBy {
                sortByTextField.text = sortBy.rawValue
                UserDefaults.standard.set(sortBy.rawValue, forKey: "payment_methods_sort_by")
            } else {
                sortByTextField.text = "None"
                UserDefaults.standard.removeObject(forKey: "payment_methods_sort_by")
            }
        } else { // Order By picker
            selectedOrderBy = orderByOptions[row]
            orderByTextField.text = selectedOrderBy
            UserDefaults.standard.set(selectedOrderBy, forKey: "payment_methods_order_by")
        }
    }
}

// MARK: - TableView DataSource and Delegate
extension PaymentMethodsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6 // buyer_id, buyer_external_identifier, sort_by, order_by, country, currency
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Payment Methods Parameters"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! PaymentMethodsTextFieldTableViewCell
        
        switch indexPath.row {
        case 0:
            cell.configure(with: buyerIdTextField)
        case 1:
            cell.configure(with: buyerExternalIdentifierTextField)
        case 2:
            cell.configure(with: sortByTextField)
        case 3:
            cell.configure(with: orderByTextField)
        case 4:
            cell.configure(with: countryTextField)
        case 5:
            cell.configure(with: currencyTextField)
        default:
            break
        }
        
        return cell
    }
}

// MARK: - Custom TextField Cell
class PaymentMethodsTextFieldTableViewCell: UITableViewCell {
    
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
