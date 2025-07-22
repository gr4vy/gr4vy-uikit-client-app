# UIKit Client App for Gr4vy Swift SDK

<div align="left">
    <img alt="Platforms" src="https://img.shields.io/badge/Platforms-iOS-yellowgreen?style=for-the-badge">
    <img alt="Build Status" src="https://img.shields.io/github/actions/workflow/status/gr4vy/gr4vy-uikit-client-app/ios.yml?branch=main&style=for-the-badge">
</div>

## Summary 

A UIKit sample application demonstrating integration with the [Gr4vy Swift SDK](https://github.com/gr4vy/gr4vy-swift). This app provides a testing interface for the SDK endpoints with persistent configuration management using programmatic UI and completion handlers.

- [Summary](#summary)
- [Architecture](#architecture)
- [App Structure](#app-structure)
  - [Tab Navigation](#tab-navigation)
  - [API Screens (4 Endpoints)](#api-screens-4-endpoints)
- [Admin Panel](#admin-panel)
  - [Core Configuration](#core-configuration)
  - [How Configuration Works](#how-configuration-works)
- [Key Features](#key-features)
  - [Completion Handler Implementation](#completion-handler-implementation)
  - [Programmatic UI](#programmatic-ui)
  - [Error Handling](#error-handling)
  - [Response Handling](#response-handling)
  - [Data Persistence](#data-persistence)
  - [Dynamic Forms](#dynamic-forms)
- [Setup Instructions](#setup-instructions)
  - [1. Dependencies](#1-dependencies)
  - [2. Configure Admin Settings](#2-configure-admin-settings)
  - [3. Test API Endpoints](#3-test-api-endpoints)
  - [4. Development Usage](#4-development-usage)
- [Customization](#customization)
  - [Adding New Endpoints](#adding-new-endpoints)
  - [Modifying UI](#modifying-ui)
  - [SDK Integration](#sdk-integration)
- [Requirements](#requirements)
- [Installation](#installation)

## Architecture

The app uses traditional UIKit patterns with completion handlers for API calls calling the Gr4vy Swift SDK directly and `UserDefaults` for persistent configuration across app sessions. The entire UI is built programmatically without storyboards.

## App Structure

### Tab Navigation
- **Home Tab**: Main navigation to API endpoint screens
- **Admin Tab**: Configuration management panel

### API Screens (4 Endpoints)

1. **Payment Options** - `POST /payment-options`
   - Configure metadata, country, currency, amount, locale, and cart items
   - Dynamic metadata key-value pairs with add/delete functionality
   - Cart items with detailed product information in scrollable forms

2. **Card Details** - `GET /card-details`  
   - Test card BIN lookup and payment method validation
   - Supports intent, subsequent payments, and merchant-initiated transactions
   - Toggle switches for boolean parameters

3. **Payment Methods** - `GET /buyers/{buyer_id}/payment-methods`
   - Retrieve stored payment methods for buyers
   - Sorting and filtering options with date inputs
   - Buyer identification by ID or external identifier

4. **Fields (Tokenize)** - `PUT /tokenize`
   - Tokenize payment methods (card, click-to-pay, or stored payment method ID)
   - Segmented control for payment method type selection
   - Dynamic form fields based on payment method type

## Admin Panel

The Admin tab provides centralized configuration for all API calls:

### Core Configuration
- **gr4vyId** - Your Gr4vy merchant identifier (required)
- **token** - API authentication token (required)  
- **server** - Environment selection (sandbox/production) via segmented control
- **timeout** - Request timeout in seconds (optional)
- **merchantId** - Used in payment options requests

### How Configuration Works
- All settings persist across app restarts using `UserDefaults`
- Empty timeout field uses SDK default timeout
- Configuration is shared across all API screens
- Switch between sandbox and production environments instantly

## Key Features

### Completion Handler Implementation
All API calls use traditional completion handler patterns:
```swift
gr4vy.paymentOptions.list(request: requestBody) { result in
    DispatchQueue.main.async {
        switch result {
        case .success(let options):
            // Handle success
        case .failure(let error):
            // Handle error
        }
    }
}
```

### Programmatic UI
- No storyboards - entire UI built programmatically
- Custom table view cells for complex forms
- Auto Layout constraints for responsive design
- Tab bar controller with navigation controllers

### Error Handling
- SDK error type handling with specific error cases
- Network error detection and visual messages
- HTTP status code display with detailed error responses
- Tappable error messages show full JSON error details

### Response Handling
- Pretty-printed JSON responses in dedicated view controller
- Copy/share functionality for debugging
- Separate navigation for success and error responses
- Color-coded response views (green for success, red for errors)

### Data Persistence
- Form data persists between app launches using UserDefaults
- Admin settings stored securely in UserDefaults
- Complex data structures (metadata, cart items) serialized as JSON

### Dynamic Forms
- Add/remove metadata entries dynamically
- Add/remove cart items with full product information
- Segmented controls for payment method type selection
- Custom table view cells for different input types

## Setup Instructions

### 1. Dependencies
This app uses CocoaPods for dependency management:

```bash
pod install
```

Open `gr4vy-uikit.xcworkspace` (not the .xcodeproj file) after running pod install.

### 2. Configure Admin Settings
- Open the **Admin** tab
- Enter your `gr4vyId` and `token`
- Select environment (sandbox/production)
- Optionally set custom timeout and merchantId

### 3. Test API Endpoints
- Navigate through the **Home** tab to each API screen
- Fill in required fields (validated with proper keyboard types)
- Tap the action button (GET/POST/PUT) to make requests
- View responses in the dedicated JSON response viewer

### 4. Development Usage
- Use as reference implementation for UIKit SDK integration
- Test various parameter combinations
- Debug API responses with detailed error information

## Customization

### Adding New Endpoints
1. Create new view controller following existing patterns
2. Add UserDefaults storage for form persistence
3. Implement completion handler-based request function with error handling
4. Add navigation in `HomeViewController.swift`

### Modifying UI
- All views use programmatic Auto Layout
- Consistent styling with custom table view cells
- Error states handled with red background styling
- Loading states with `UIActivityIndicatorView`

### SDK Integration

```swift
let server: Gr4vyServer = serverEnvironment == "production" ? .production : .sandbox
let timeoutInterval = TimeInterval(Double(timeout) ?? 30.0)

guard let gr4vy = try? Gr4vy(
    gr4vyId: gr4vyID,
    token: token,
    server: server,
    timeout: timeoutInterval
) else {
    showError("Failed to configure Gr4vy SDK")
    return
}
```

## Requirements

- iOS 16.0+
- Xcode 16.0+
- Swift 5.7+
- CocoaPods for dependency management
- Gr4vy Swift SDK (installed via CocoaPods)

## Installation

1. Clone the repository
2. Run `pod install` in the project directory
3. Open `gr4vy-uikit.xcworkspace`
4. Build and run the project

This UIKit implementation provides the same functionality as the SwiftUI version while demonstrating traditional iOS development patterns and completion handler-based asynchronous programming. 