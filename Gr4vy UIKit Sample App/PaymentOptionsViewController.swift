//
//  PaymentOptionsViewController.swift
//  Gr4vy UIKit Sample App
//
//  Created by Gr4vy
//

import UIKit
import gr4vy_swift

struct MetadataEntry {
    let id = UUID()
    var key: String
    var value: String
    
    init(key: String = "", value: String = "") {
        self.key = key
        self.value = value
    }
}

struct CartItemEntry {
    let id = UUID()
    var name: String = ""
    var quantity: String = ""
    var unitAmount: String = ""
    var discountAmount: String = ""
    var taxAmount: String = ""
    var externalIdentifier: String = ""
    var sku: String = ""
    var productUrl: String = ""
    var imageUrl: String = ""
    var categories: String = ""
    var productType: String = ""
    var sellerCountry: String = ""
}

class PaymentOptionsViewController: UIViewController {
    
    internal let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = UIView()
    private let errorLabel = UILabel()
    
    // Form fields
    let countryTextField = UITextField()
    let currencyTextField = UITextField()
    let amountTextField = UITextField()
    let localeTextField = UITextField()
    
    // Dynamic data
    var metadataEntries: [MetadataEntry] = []
    var cartItems: [CartItemEntry] = []
    
    // State
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupErrorView()
        loadSavedData()
        addInitialEntries()
    }
    
    private func setupUI() {
        title = "Payment Options"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Add POST button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "POST",
            style: .done,
            target: self,
            action: #selector(postButtonTapped)
        )
        
        // Configure table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(MetadataTableViewCell.self, forCellReuseIdentifier: "MetadataCell")
        tableView.register(CartItemTableViewCell.self, forCellReuseIdentifier: "CartItemCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ButtonCell")
        
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
        // Configure table view properties
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
        
        // Add tap gesture to error view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(errorViewTapped))
        errorView.addGestureRecognizer(tapGesture)
    }
    
    private func setupFormFields() {
        countryTextField.placeholder = "country"
        countryTextField.autocapitalizationType = .none
        countryTextField.autocorrectionType = .no
        countryTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        currencyTextField.placeholder = "currency"
        currencyTextField.autocapitalizationType = .none
        currencyTextField.autocorrectionType = .no
        currencyTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        amountTextField.placeholder = "amount"
        amountTextField.keyboardType = .numberPad
        amountTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        localeTextField.placeholder = "locale"
        localeTextField.autocapitalizationType = .none
        localeTextField.autocorrectionType = .no
        localeTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func loadSavedData() {
        countryTextField.text = UserDefaults.standard.string(forKey: "payment_options_country") ?? ""
        currencyTextField.text = UserDefaults.standard.string(forKey: "payment_options_currency") ?? ""
        amountTextField.text = UserDefaults.standard.string(forKey: "payment_options_amount") ?? ""
        localeTextField.text = UserDefaults.standard.string(forKey: "payment_options_locale") ?? ""
        
        // Load metadata entries
        if let data = UserDefaults.standard.data(forKey: "payment_options_metadata_entries"),
           let entries = try? JSONDecoder().decode([MetadataEntryData].self, from: data) {
            metadataEntries = entries.map { MetadataEntry(key: $0.key, value: $0.value) }
        }
        
        // Load cart items
        if let data = UserDefaults.standard.data(forKey: "payment_options_cart_items"),
           let items = try? JSONDecoder().decode([CartItemEntryData].self, from: data) {
            cartItems = items.map { data in
                var item = CartItemEntry()
                item.name = data.name
                item.quantity = data.quantity
                item.unitAmount = data.unitAmount
                item.discountAmount = data.discountAmount
                item.taxAmount = data.taxAmount
                item.externalIdentifier = data.externalIdentifier
                item.sku = data.sku
                item.productUrl = data.productUrl
                item.imageUrl = data.imageUrl
                item.categories = data.categories
                item.productType = data.productType
                item.sellerCountry = data.sellerCountry
                return item
            }
        }
    }
    
    private func addInitialEntries() {
        if metadataEntries.isEmpty {
            metadataEntries.append(MetadataEntry())
        }
        
        if cartItems.isEmpty {
            cartItems.append(CartItemEntry())
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let value = textField.text ?? ""
        
        switch textField {
        case countryTextField:
            UserDefaults.standard.set(value, forKey: "payment_options_country")
        case currencyTextField:
            UserDefaults.standard.set(value, forKey: "payment_options_currency")
        case amountTextField:
            UserDefaults.standard.set(value, forKey: "payment_options_amount")
        case localeTextField:
            UserDefaults.standard.set(value, forKey: "payment_options_locale")
        default:
            break
        }
    }
    
    func saveMetadataEntries() {
        let data = metadataEntries.map { MetadataEntryData(key: $0.key, value: $0.value) }
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "payment_options_metadata_entries")
        }
    }
    
    func saveCartItems() {
        let data = cartItems.map { 
            CartItemEntryData(
                name: $0.name,
                quantity: $0.quantity,
                unitAmount: $0.unitAmount,
                discountAmount: $0.discountAmount,
                taxAmount: $0.taxAmount,
                externalIdentifier: $0.externalIdentifier,
                sku: $0.sku,
                productUrl: $0.productUrl,
                imageUrl: $0.imageUrl,
                categories: $0.categories,
                productType: $0.productType,
                sellerCountry: $0.sellerCountry
            )
        }
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "payment_options_cart_items")
        }
    }
    
    @objc private func postButtonTapped() {
        sendRequest()
    }
    
    @objc private func errorViewTapped() {
        // Handle error view tap - could show more details
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
        let merchantId = UserDefaults.standard.string(forKey: "merchantId")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
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
        
        // Prepare metadata
        var metadata: [String: String] = [:]
        let validMetadataEntries = metadataEntries.filter {
            !$0.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        for entry in validMetadataEntries {
            metadata[entry.key.trimmingCharacters(in: .whitespacesAndNewlines)] =
            entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Prepare cart items
        var gr4vyCartItems: [Gr4vyPaymentOptionCartItem] = []
        let validCartItems = cartItems.filter { item in
            !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !item.quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !item.unitAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        for item in validCartItems {
            let categories = item.categories.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
            item.categories.trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: ",")
                .map { String($0.trimmingCharacters(in: .whitespaces)) }
            
            let cartItem = Gr4vyPaymentOptionCartItem(
                name: item.name.trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: Int(item.quantity.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1,
                unitAmount: Int(item.unitAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
                discountAmount: item.discountAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
                    Int(item.discountAmount.trimmingCharacters(in: .whitespacesAndNewlines)),
                taxAmount: item.taxAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
                    Int(item.taxAmount.trimmingCharacters(in: .whitespacesAndNewlines)),
                externalIdentifier: item.externalIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
                    item.externalIdentifier.trimmingCharacters(in: .whitespacesAndNewlines),
                sku: item.sku.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
                    item.sku.trimmingCharacters(in: .whitespacesAndNewlines),
                productUrl: item.productUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
                    item.productUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                imageUrl: item.imageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
                    item.imageUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                categories: categories,
                productType: item.productType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
                    item.productType.trimmingCharacters(in: .whitespacesAndNewlines),
                sellerCountry: item.sellerCountry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
                    item.sellerCountry.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            gr4vyCartItems.append(cartItem)
        }
        
        let requestBody = Gr4vyPaymentOptionRequest(
            merchantId: merchantId,
            metadata: metadata,
            country: countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil :
                countryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            currency: currencyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil :
                currencyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil :
                Int(amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""),
            locale: localeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? "en-GB" :
                (localeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "en-GB"),
            cartItems: gr4vyCartItems.isEmpty ? nil : gr4vyCartItems
        )
        
        gr4vy.paymentOptions.list(request: requestBody) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                
                switch result {
                case .success(let options):
                    // Convert the response to JSON for display
                    do {
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        let jsonData = try encoder.encode(options)
                        
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
                showError("Cannot find server. Please check your Merchant ID (\(gr4vyID)). The URL being called is: https://api.\(gr4vyID).gr4vy.app/payment-options")
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
            showError("Failed to get payment options: \(error.localizedDescription)")
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

// MARK: - Codable Data Structures
struct MetadataEntryData: Codable {
    let key: String
    let value: String
}

struct CartItemEntryData: Codable {
    let name: String
    let quantity: String
    let unitAmount: String
    let discountAmount: String
    let taxAmount: String
    let externalIdentifier: String
    let sku: String
    let productUrl: String
    let imageUrl: String
    let categories: String
    let productType: String
    let sellerCountry: String
}

// The table view implementation will be in a separate extension due to file size... 
