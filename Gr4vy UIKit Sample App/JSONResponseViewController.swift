//
//  JSONResponseViewController.swift
//  Gr4vy UIKit Sample App
//
//  Created by Gr4vy
//

import UIKit

class JSONResponseViewController: UIViewController {
    
    private let textView = UITextView()
    
    var responseData: Data?
    var errorStatusCode: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        
        // Configure text view
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = true
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
        
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            // Text view constraints - fill the entire safe area
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        
        // Handle empty response (e.g., 204 No Content)
        if responseData.isEmpty {
            textView.text = "Request completed successfully.\n\nNo response body (empty response)."
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
                
            } else {
                textView.text = "Unable to convert response to string"
            }
        } catch {
            if let rawString = String(data: responseData, encoding: .utf8) {
                var displayText = ""
                
                if let statusCode = errorStatusCode {
                    displayText += "HTTP Status: \(statusCode)\n\n"
                }
                
                displayText += rawString.isEmpty ? "Request completed successfully.\n\nEmpty response body." : rawString
                textView.text = displayText
            } else {
                textView.text = "Unable to decode response data"
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        }
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
