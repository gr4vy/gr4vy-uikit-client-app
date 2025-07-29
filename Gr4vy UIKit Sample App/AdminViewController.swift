//
//  AdminViewController.swift
//  Gr4vy UIKit Sample App
//
//  Created by Gr4vy
//

import UIKit

class AdminViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // Form fields
    private let merchantIdTextField = UITextField()
    private let gr4vyIdTextField = UITextField()
    private let tokenTextField = UITextField()
    private let timeoutTextField = UITextField()
    private let serverSegmentedControl = UISegmentedControl(items: ["sandbox", "production"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadSavedSettings()
    }
    
    private func setupUI() {
        title = "Admin"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Configure table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AdminTextFieldTableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(SegmentedControlTableViewCell.self, forCellReuseIdentifier: "SegmentedControlCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ButtonCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupTextFields()
    }
    
    private func setupTableView() {
        // Configure text fields
        setupTextFields()
    }
    
    private func setupTextFields() {
        // Configure merchant ID text field
        merchantIdTextField.placeholder = "merchantId"
        merchantIdTextField.autocapitalizationType = .none
        merchantIdTextField.autocorrectionType = .no
        merchantIdTextField.textContentType = .none
        merchantIdTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Configure gr4vy ID text field
        gr4vyIdTextField.placeholder = "gr4vyId"
        gr4vyIdTextField.autocapitalizationType = .none
        gr4vyIdTextField.autocorrectionType = .no
        gr4vyIdTextField.textContentType = .none
        gr4vyIdTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Configure token text field
        tokenTextField.placeholder = "token"
        tokenTextField.autocapitalizationType = .none
        tokenTextField.autocorrectionType = .no
        tokenTextField.textContentType = .none
        tokenTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Configure timeout text field
        timeoutTextField.placeholder = "timeout (seconds)"
        timeoutTextField.keyboardType = .numberPad
        timeoutTextField.autocapitalizationType = .none
        timeoutTextField.autocorrectionType = .no
        timeoutTextField.textContentType = .none
        timeoutTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Configure server segmented control
        serverSegmentedControl.selectedSegmentIndex = 0
        serverSegmentedControl.addTarget(self, action: #selector(serverSegmentedControlChanged(_:)), for: .valueChanged)
    }
    
    private func loadSavedSettings() {
        merchantIdTextField.text = UserDefaults.standard.string(forKey: "merchantId") ?? ""
        gr4vyIdTextField.text = UserDefaults.standard.string(forKey: "gr4vyId") ?? ""
        tokenTextField.text = UserDefaults.standard.string(forKey: "apiToken") ?? ""
        timeoutTextField.text = UserDefaults.standard.string(forKey: "timeout") ?? ""
        
        let serverEnvironment = UserDefaults.standard.string(forKey: "serverEnvironment") ?? "sandbox"
        serverSegmentedControl.selectedSegmentIndex = serverEnvironment == "production" ? 1 : 0
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let value = textField.text ?? ""
        
        switch textField {
        case merchantIdTextField:
            UserDefaults.standard.set(value, forKey: "merchantId")
        case gr4vyIdTextField:
            UserDefaults.standard.set(value, forKey: "gr4vyId")
        case tokenTextField:
            UserDefaults.standard.set(value, forKey: "apiToken")
        case timeoutTextField:
            UserDefaults.standard.set(value, forKey: "timeout")
        default:
            break
        }
    }
    
    @objc private func serverSegmentedControlChanged(_ sender: UISegmentedControl) {
        let serverEnvironment = sender.selectedSegmentIndex == 1 ? "production" : "sandbox"
        UserDefaults.standard.set(serverEnvironment, forKey: "serverEnvironment")
    }
    
    @objc private func saveButtonTapped() {
        let alert = UIAlertController(title: "Settings Saved", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension AdminViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 5 : 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "API Configuration" : nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! AdminTextFieldTableViewCell
                cell.configure(with: merchantIdTextField)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! AdminTextFieldTableViewCell
                cell.configure(with: gr4vyIdTextField)
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! AdminTextFieldTableViewCell
                cell.configure(with: tokenTextField)
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlCell", for: indexPath) as! SegmentedControlTableViewCell
                cell.configure(with: serverSegmentedControl, title: "server")
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! AdminTextFieldTableViewCell
                cell.configure(with: timeoutTextField)
                return cell
            default:
                break
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
            cell.textLabel?.text = "Save"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = UIColor.systemBlue
            cell.selectionStyle = .none
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == 0 {
            saveButtonTapped()
        }
    }
}

// MARK: - Custom Table View Cells

class AdminTextFieldTableViewCell: UITableViewCell {
    private var textField: UITextField?
    
    func configure(with textField: UITextField) {
        self.textField = textField
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
}

class SegmentedControlTableViewCell: UITableViewCell {
    private var titleLabel: UILabel?
    private var segmentedControl: UISegmentedControl?
    
    func configure(with segmentedControl: UISegmentedControl, title: String) {
        self.segmentedControl = segmentedControl
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentedControl)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
} 
