//
//  JSONResponseViewController.swift
//  Gr4vy UIKit Sample App
//
//  Created by Gr4vy
//

import UIKit

class JSONResponseViewController: UIViewController {
    
    private let textView = UITextView()
    private let scrollView = UIScrollView()
    
    var responseData: Data?
    var errorStatusCode: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayResponse()
    }
    
    private func setupUI() {
        title = "Response"
        view.backgroundColor = UIColor.systemBackground
        
        // Add share button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareButtonTapped)
        )
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Configure text view
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        // Set background color based on whether it's an error
        if errorStatusCode != nil {
            textView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
            textView.textColor = UIColor.systemRed
        } else {
            textView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
            textView.textColor = UIColor.label
        }
        
        scrollView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Text view constraints
            textView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            textView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Add tap gesture to copy on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(textViewTapped))
        textView.addGestureRecognizer(tapGesture)
    }
    
    private func displayResponse() {
        guard let responseData = responseData else {
            textView.text = "No response data"
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: responseData, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            
            if let prettyString = String(data: prettyData, encoding: .utf8) {
                var displayText = ""
                
                if let statusCode = errorStatusCode {
                    displayText += "HTTP Status: \(statusCode)\n\n"
                }
                
                displayText += prettyString
                textView.text = displayText
            }
        } catch {
            if let rawString = String(data: responseData, encoding: .utf8) {
                var displayText = ""
                
                if let statusCode = errorStatusCode {
                    displayText += "HTTP Status: \(statusCode)\n\n"
                }
                
                displayText += rawString
                textView.text = displayText
            } else {
                textView.text = "Unable to decode response data"
            }
        }
        
        // Adjust content size
        textView.sizeToFit()
    }
    
    @objc private func shareButtonTapped() {
        guard let text = textView.text, !text.isEmpty else { return }
        
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // For iPad
        if let popover = activityController.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityController, animated: true)
    }
    
    @objc private func textViewTapped() {
        guard let text = textView.text, !text.isEmpty else { return }
        
        UIPasteboard.general.string = text
        
        // Show feedback
        let alert = UIAlertController(title: "Copied", message: "Response copied to clipboard", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
} 