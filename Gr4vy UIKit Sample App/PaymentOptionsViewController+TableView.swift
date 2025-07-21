//
//  PaymentOptionsViewController+TableView.swift
//  Gr4vy UIKit Sample App
//
//  Created by Gr4vy
//

import UIKit

// MARK: - PaymentOptionsViewController Table View Extensions
extension PaymentOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // Basic fields, Metadata, Cart Items, Loading
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4 // country, currency, amount, locale
        case 1: return metadataEntries.count + 1 // metadata entries + add button
        case 2: return cartItems.count + 1 // cart items + add button
        case 3: return isLoading ? 1 : 0 // loading indicator
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Basic Information"
        case 1: return "Metadata"
        case 2: return "Cart Items"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
            switch indexPath.row {
            case 0:
                cell.configure(with: countryTextField)
            case 1:
                cell.configure(with: currencyTextField)
            case 2:
                cell.configure(with: amountTextField)
            case 3:
                cell.configure(with: localeTextField)
            default:
                break
            }
            return cell
            
        case 1:
            if indexPath.row < metadataEntries.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MetadataCell", for: indexPath) as! MetadataTableViewCell
                cell.configure(
                    with: metadataEntries[indexPath.row],
                    onKeyChange: { [weak self] newKey in
                        self?.metadataEntries[indexPath.row].key = newKey
                        self?.saveMetadataEntries()
                    },
                    onValueChange: { [weak self] newValue in
                        self?.metadataEntries[indexPath.row].value = newValue
                        self?.saveMetadataEntries()
                    },
                    onDelete: { [weak self] in
                        guard let self = self else { return }
                        self.metadataEntries.remove(at: indexPath.row)
                        self.saveMetadataEntries()
                        self.tableView.reloadData()
                    }
                )
                return cell
            } else {
                // Add button
                let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
                cell.textLabel?.text = "Add Metadata Entry"
                cell.textLabel?.textColor = UIColor.systemBlue
                cell.textLabel?.textAlignment = .center
                return cell
            }
            
        case 2:
            if indexPath.row < cartItems.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemCell", for: indexPath) as! CartItemTableViewCell
                cell.configure(
                    with: cartItems[indexPath.row],
                    onChange: { [weak self] in
                        self?.saveCartItems()
                    },
                    onDelete: { [weak self] in
                        guard let self = self else { return }
                        self.cartItems.remove(at: indexPath.row)
                        self.saveCartItems()
                        self.tableView.reloadData()
                    }
                )
                return cell
            } else {
                // Add button
                let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
                cell.textLabel?.text = "Add Cart Item"
                cell.textLabel?.textColor = UIColor.systemBlue
                cell.textLabel?.textAlignment = .center
                return cell
            }
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
            cell.textLabel?.text = "Sending request..."
            cell.textLabel?.textColor = UIColor.secondaryLabel
            cell.textLabel?.textAlignment = .center
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == metadataEntries.count {
            // Add metadata entry
            metadataEntries.append(MetadataEntry())
            tableView.insertRows(at: [IndexPath(row: indexPath.row, section: 1)], with: .fade)
            saveMetadataEntries()
        } else if indexPath.section == 2 && indexPath.row == cartItems.count {
            // Add cart item
            cartItems.append(CartItemEntry())
            tableView.insertRows(at: [IndexPath(row: indexPath.row, section: 2)], with: .fade)
            saveCartItems()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 2:
            if indexPath.row < cartItems.count {
                return 600 // Large height for cart item cells
            }
        default:
            break
        }
        return UITableView.automaticDimension
    }
}

// MARK: - Custom Table View Cells

class MetadataTableViewCell: UITableViewCell {
    
    private let keyTextField = UITextField()
    private let valueTextField = UITextField()
    private let deleteButton = UIButton(type: .system)
    
    private var onKeyChange: ((String) -> Void)?
    private var onValueChange: ((String) -> Void)?
    private var onDelete: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        keyTextField.translatesAutoresizingMaskIntoConstraints = false
        keyTextField.placeholder = "Key"
        keyTextField.borderStyle = .roundedRect
        keyTextField.autocapitalizationType = .none
        keyTextField.autocorrectionType = .no
        keyTextField.addTarget(self, action: #selector(keyTextFieldChanged), for: .editingChanged)
        
        valueTextField.translatesAutoresizingMaskIntoConstraints = false
        valueTextField.placeholder = "Value"
        valueTextField.borderStyle = .roundedRect
        valueTextField.autocapitalizationType = .none
        valueTextField.autocorrectionType = .no
        valueTextField.addTarget(self, action: #selector(valueTextFieldChanged), for: .editingChanged)
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = UIColor.systemRed
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        contentView.addSubview(keyTextField)
        contentView.addSubview(valueTextField)
        contentView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            keyTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            keyTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            keyTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4, constant: -24),
            
            valueTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            valueTextField.leadingAnchor.constraint(equalTo: keyTextField.trailingAnchor, constant: 8),
            valueTextField.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
            
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44),
            
            keyTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            valueTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with entry: MetadataEntry, onKeyChange: @escaping (String) -> Void, onValueChange: @escaping (String) -> Void, onDelete: @escaping () -> Void) {
        keyTextField.text = entry.key
        valueTextField.text = entry.value
        self.onKeyChange = onKeyChange
        self.onValueChange = onValueChange
        self.onDelete = onDelete
    }
    
    @objc private func keyTextFieldChanged() {
        onKeyChange?(keyTextField.text ?? "")
    }
    
    @objc private func valueTextFieldChanged() {
        onValueChange?(valueTextField.text ?? "")
    }
    
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
}

class CartItemTableViewCell: UITableViewCell {
    
    private let scrollView = UIScrollView()
    private let wrapperView = UIView()
    private let stackView = UIStackView()
    private let deleteButton = UIButton(type: .system)
    
    // Text fields
    private let nameTextField = UITextField()
    private let quantityTextField = UITextField()
    private let unitAmountTextField = UITextField()
    private let discountAmountTextField = UITextField()
    private let taxAmountTextField = UITextField()
    private let externalIdentifierTextField = UITextField()
    private let skuTextField = UITextField()
    private let productUrlTextField = UITextField()
    private let imageUrlTextField = UITextField()
    private let categoriesTextField = UITextField()
    private let productTypeTextField = UITextField()
    private let sellerCountryTextField = UITextField()
    
    private var onChange: (() -> Void)?
    private var onDelete: (() -> Void)?
    private var cartItem: CartItemEntry?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        self.contentView.addSubview(scrollView)
        
        // Configure wrapper view
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(wrapperView)
        
        // Configure stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fill
        wrapperView.addSubview(stackView)
        
        // Configure delete button
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = UIColor.systemRed
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        wrapperView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 600),
            
            wrapperView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            wrapperView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            wrapperView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            wrapperView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            wrapperView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: 8),
            deleteButton.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44),
            
            stackView.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -16)
        ])
        
        setupTextFields()
        addTextFieldsToStackView()
    }
    
    private func setupTextFields() {
        let textFields = [
            (nameTextField, "name"),
            (quantityTextField, "quantity"),
            (unitAmountTextField, "unit_amount"),
            (discountAmountTextField, "discount_amount"),
            (taxAmountTextField, "tax_amount"),
            (externalIdentifierTextField, "external_identifier"),
            (skuTextField, "sku"),
            (productUrlTextField, "product_url"),
            (imageUrlTextField, "image_url"),
            (categoriesTextField, "categories (comma separated)"),
            (productTypeTextField, "product_type"),
            (sellerCountryTextField, "seller_country")
        ]
        
        for (textField, placeholder) in textFields {
            textField.placeholder = placeholder
            textField.borderStyle = .roundedRect
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
            
            if placeholder.contains("amount") || placeholder == "quantity" {
                textField.keyboardType = .numberPad
            } else if placeholder.contains("url") {
                textField.keyboardType = .URL
            }
        }
    }
    
    private func addTextFieldsToStackView() {
        let textFields = [
            nameTextField, quantityTextField, unitAmountTextField,
            discountAmountTextField, taxAmountTextField, externalIdentifierTextField,
            skuTextField, productUrlTextField, imageUrlTextField,
            categoriesTextField, productTypeTextField, sellerCountryTextField
        ]
        
        for textField in textFields {
            stackView.addArrangedSubview(textField)
        }
    }
    
    func configure(with item: CartItemEntry, onChange: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.cartItem = item
        self.onChange = onChange
        self.onDelete = onDelete
        
        nameTextField.text = item.name
        quantityTextField.text = item.quantity
        unitAmountTextField.text = item.unitAmount
        discountAmountTextField.text = item.discountAmount
        taxAmountTextField.text = item.taxAmount
        externalIdentifierTextField.text = item.externalIdentifier
        skuTextField.text = item.sku
        productUrlTextField.text = item.productUrl
        imageUrlTextField.text = item.imageUrl
        categoriesTextField.text = item.categories
        productTypeTextField.text = item.productType
        sellerCountryTextField.text = item.sellerCountry
    }
    
    @objc private func textFieldChanged(_ textField: UITextField) {
        guard var item = cartItem else { return }
        
        let value = textField.text ?? ""
        
        switch textField {
        case nameTextField: item.name = value
        case quantityTextField: item.quantity = value
        case unitAmountTextField: item.unitAmount = value
        case discountAmountTextField: item.discountAmount = value
        case taxAmountTextField: item.taxAmount = value
        case externalIdentifierTextField: item.externalIdentifier = value
        case skuTextField: item.sku = value
        case productUrlTextField: item.productUrl = value
        case imageUrlTextField: item.imageUrl = value
        case categoriesTextField: item.categories = value
        case productTypeTextField: item.productType = value
        case sellerCountryTextField: item.sellerCountry = value
        default: break
        }
        
        self.cartItem = item
        onChange?()
    }
    
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
} 
