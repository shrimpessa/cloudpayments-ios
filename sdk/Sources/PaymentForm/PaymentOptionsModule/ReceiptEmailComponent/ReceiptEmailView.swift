//
//  ReceiptEmailView.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

final class ReceiptEmailView: UIView, UITextFieldDelegate {
    
    // MARK: - Public
    
    var setButtonsEnabled: ((Bool) -> Void)?
    var isReceiptSwitchOn: (() -> Bool)?
    var emailBehavior: EmailBehaviorType = .optional
    
    var email: String? {
        get { textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) }
        set { textField.text = newValue }
    }
    
    // MARK: - Subviews
    
    private let borderView = UIView()
    private let textField = UITextField()
    private let errorLabel = UILabel()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Border
        borderView.layer.cornerRadius = 8
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = UIColor.border.cgColor
        borderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(borderView)
        
        // TextField
        textField.borderStyle = .none
        textField.placeholder = "E-mail"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .emailAddress
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        borderView.addSubview(textField)
        
        // Error label
        errorLabel.textColor = UIColor.errorBorder
        errorLabel.font = .systemFont(ofSize: 13)
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(errorLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 56),
            
            textField.topAnchor.constraint(equalTo: borderView.topAnchor),
            textField.leadingAnchor.constraint(equalTo: borderView.leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: borderView.trailingAnchor, constant: -8),
            textField.bottomAnchor.constraint(equalTo: borderView.bottomAnchor),
            
            errorLabel.topAnchor.constraint(equalTo: borderView.bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Validation
    
    @objc private func textFieldChanged() {
        validateEmail(textField.text)
    }
    
    func validateEmail(_ text: String?) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let isValid: Bool = {
            switch emailBehavior {
            case .required:
                return true
            case .optional:
                return isReceiptSwitchOn?() ?? false
            case .hidden:
                return false
            }
        }()
        
        if trimmed.isEmpty {
            if isValid {
                setState(.error("Для оплаты введите E-mail"), isEditing: false)
                setButtonsEnabled?(false)
            } else {
                setState(.empty, isEditing: false)
                setButtonsEnabled?(true)
            }
            return
        }
        
        if trimmed.emailIsValid() {
            setState(.valid, isEditing: false)
            setButtonsEnabled?(true)
        } else {
            setState(.error("Введите верный E-mail"), isEditing: false)
            setButtonsEnabled?(false)
        }
    }
    
    private func setState(_ state: EmailState, isEditing: Bool) {
        switch state {
        case .empty:
            borderView.layer.borderColor = isEditing ? UIColor.mainBlue.cgColor : UIColor.border.cgColor
            textField.textColor = UIColor.mainText
            errorLabel.isHidden = true
        case .valid:
            borderView.layer.borderColor = isEditing ? UIColor.mainBlue.cgColor : UIColor.border.cgColor
            textField.textColor = UIColor.mainText
            errorLabel.isHidden = true
        case .error(let message):
            borderView.layer.borderColor = UIColor.errorBorder.cgColor
            textField.textColor = UIColor.errorBorder
            errorLabel.text = message
            errorLabel.isHidden = false
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let trimmed = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            setState(.empty, isEditing: true)
        } else if trimmed.emailIsValid() {
            setState(.valid, isEditing: true)
        } else {
            setState(.error("Введите верный E-mail"), isEditing: true)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        validateEmail(textField.text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - State Enum
    
    private enum EmailState {
        case empty
        case valid
        case error(String)
    }
}

extension ReceiptEmailView {

    /// Email введён и валиден с учётом emailBehavior и switch
    func isEmailValid() -> Bool {
        let trimmed = email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return false }

        switch emailBehavior {
        case .required:
            return trimmed.emailIsValid()

        case .optional:
            guard isReceiptSwitchOn?() == true else { return false }
            return trimmed.emailIsValid()

        case .hidden:
            return false
        }
    }
}
