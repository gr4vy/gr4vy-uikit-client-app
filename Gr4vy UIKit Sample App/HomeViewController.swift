//
//  HomeViewController.swift
//  Gr4vy UIKit Sample App
//
//  Created by Gr4vy
//

import UIKit

class HomeViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupButtons()
    }
    
    private func setupUI() {
        title = "Gr4vy Native SDK"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = UIColor.systemBackground
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Configure content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Configure stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fill
        stackView.alignment = .fill
        contentView.addSubview(stackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Stack view constraints
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupButtons() {
        // Add spacer at top
        let topSpacer = UIView()
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(topSpacer)
        
        // Payment Options button
        let paymentOptionsButton = createButtonView(
            title: "Payment Options",
            systemImage: "creditcard.fill"
        ) { [weak self] in
            let paymentOptionsVC = PaymentOptionsViewController()
            self?.navigationController?.pushViewController(paymentOptionsVC, animated: true)
        }
        stackView.addArrangedSubview(paymentOptionsButton)
        
        // Fields button
        let fieldsButton = createButtonView(
            title: "Fields",
            systemImage: "textformat"
        ) { [weak self] in
            let fieldsVC = FieldsViewController()
            self?.navigationController?.pushViewController(fieldsVC, animated: true)
        }
        stackView.addArrangedSubview(fieldsButton)
        
        // Card Details button
        let cardDetailsButton = createButtonView(
            title: "Card Details",
            systemImage: "creditcard"
        ) { [weak self] in
            let cardDetailsVC = CardDetailsViewController()
            self?.navigationController?.pushViewController(cardDetailsVC, animated: true)
        }
        stackView.addArrangedSubview(cardDetailsButton)
        
        // Payment Methods button
        let paymentMethodsButton = createButtonView(
            title: "Payment Methods",
            systemImage: "list.bullet"
        ) { [weak self] in
            let paymentMethodsVC = PaymentMethodsViewController()
            self?.navigationController?.pushViewController(paymentMethodsVC, animated: true)
        }
        stackView.addArrangedSubview(paymentMethodsButton)
        
        // Add spacer at bottom
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(bottomSpacer)
    }
    
    private func createButtonView(title: String, systemImage: String, action: @escaping () -> Void) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        containerView.addSubview(button)
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: systemImage)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor.label
        button.addSubview(iconImageView)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor.label
        button.addSubview(titleLabel)
        
        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.tintColor = UIColor.secondaryLabel
        button.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            // Container height
            containerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Button fills container
            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Icon constraints
            iconImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Title constraints
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            // Chevron constraints
            chevronImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
            chevronImageView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
        
        return containerView
    }
} 