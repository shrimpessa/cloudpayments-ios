//
//  PaymentCardContentViewController.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit

final class PaymentCardContentViewController: BaseViewController {

    var onCardNumberCompleted: (() -> Void)?
    var requestBinInfo: ((_ cleanCard: String, _ completion: @escaping (BinInfoLight?) -> Void) -> Void)?
    var onPayTapped: ((_ card: String, _ exp: String, _ cvv: String) -> Void)?
    func setAmountText(_ text: String?) {
        guard let text, !text.isEmpty else { return }
        if var cfg = payButton.configuration {
            cfg.title = "Оплатить \(text)"
            payButton.configuration = cfg
        } else {
            payButton.setTitle("Оплатить \(text)", for: .normal)
        }
    }

    // MARK: - Init
    private let amountText: String?
    init(amountText: String? = nil) {
        self.amountText = amountText
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    // MARK: - UI
    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = .label
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Оплата картой"
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    let cardNumberField: UITextField = {
        let tf = WhiteTextFieldComponent()
        tf.keyboardType = .numberPad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    let expiryField: UITextField = {
        let tf = WhiteTextFieldComponent()
        tf.keyboardType = .numberPad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    let cvvField: UITextField = {
        let tf = WhiteTextFieldComponent()
        tf.keyboardType = .numberPad
        tf.isSecureTextEntry = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let cardPlaceholder = UILabel()
    private let expiryPlaceholder = UILabel()
    private let cvvPlaceholder = UILabel()
    private let cardContainer = UIView()
    private let expiryContainer = UIView()
    private let cvvContainer = UIView()
    private var cardNumberTimer: Timer?
    private var lastScheduledCleanCard: String?
    private var detectedCardType: CardType?
    
    private var cardFillStartedSent = false
    private var cardFillFinishedSent = false
    private var cardTypeDefinitionSent = false
    private var expiredDateEventSent = false
    private var cvvEventSent = false
    
    var onCardDataFillStarted: (() -> Void)?
    var onCardDataFillFinished: (() -> Void)?
    var onCardTypeDefined: ((CardType) -> Void)?
    var onExpiredDateFilled: (() -> Void)?
    var onCvvFilled: (() -> Void)?

    private let cardTypeIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()

    private let cvvEyeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(EyeStatus.byDefault.image, for: .normal)
        b.tintColor = .secondaryLabel
        return b
    }()

    private let payButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .fixed
        config.background.cornerRadius = 8
        config.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.title = "Оплатить"
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return b
    }()

    private let cpLogoView: CloudPaymentsLogoView = {
        let v = CloudPaymentsLogoView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let fieldsVStack: UIStackView = {
        let st = UIStackView()
        st.axis = .vertical
        st.alignment = .fill
        st.spacing = 12
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()

    private let mmCvvHStack: UIStackView = {
        let st = UIStackView()
        st.axis = .horizontal
        st.alignment = .fill
        st.distribution = .fillEqually
        st.spacing = 12
        st.translatesAutoresizingMaskIntoConstraints = false
        return st
    }()

    // MARK: - State & Flags
    private var isCvvRequired: Bool = true
    private var cardTouched = false
    private var expTouched  = false
    private var cvvTouched  = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        configureTextFields()
        setAmountText(amountText)
        applyVisualState()

        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(tapOutside)
        )

        tap.cancelsTouchesInView = false
        tap.delegate = self

        view.addGestureRecognizer(tap)
    }
    
    @objc private func tapOutside() {
        view.endEditing(true)
    }
    
    deinit {
        cardNumberTimer?.invalidate()
    }

    // MARK: - Layout & UI helpers
    private func setupUI() {
        view.backgroundColor = .white

        setupPlaceholderLabel(cardPlaceholder,   text: PlaceholderType.correctCard.toString())
        setupPlaceholderLabel(expiryPlaceholder, text: PlaceholderType.correctExpDate.toString())
        setupPlaceholderLabel(cvvPlaceholder,    text: PlaceholderType.correctCvv.toString())

        view.addSubview(handleView)
        view.addSubview(titleLabel)
        view.addSubview(fieldsVStack)
        view.addSubview(payButton)
        view.addSubview(cpLogoView)

        configureFieldContainerWithAccessory(
            cardContainer,
            field: cardNumberField,
            placeholder: cardPlaceholder,
            accessory: cardTypeIcon,
            accessorySize: CGSize(width: 40, height: 30)
        )

        configureFieldContainer(
            expiryContainer,
            field: expiryField,
            placeholder: expiryPlaceholder
        )

        configureFieldContainerWithAccessory(
            cvvContainer,
            field: cvvField,
            placeholder: cvvPlaceholder,
            accessory: cvvEyeButton,
            accessorySize: CGSize(width: 22, height: 18)
        )

        mmCvvHStack.addArrangedSubview(expiryContainer)
        mmCvvHStack.addArrangedSubview(cvvContainer)
        fieldsVStack.addArrangedSubview(cardContainer)
        fieldsVStack.addArrangedSubview(mmCvvHStack)

        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 135),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            fieldsVStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            fieldsVStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            fieldsVStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            payButton.topAnchor.constraint(equalTo: fieldsVStack.bottomAnchor, constant: 20),
            payButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            payButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            payButton.heightAnchor.constraint(equalToConstant: 56),

            cpLogoView.topAnchor.constraint(equalTo: payButton.bottomAnchor, constant: 20),
            cpLogoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cpLogoView.heightAnchor.constraint(equalToConstant: 24),
            cpLogoView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            cpLogoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)
        cvvEyeButton.addTarget(self, action: #selector(toggleCvvSecure), for: .touchUpInside)
    }

    private func setupPlaceholderLabel(_ l: UILabel, text: String) {
        l.text = text
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setContentHuggingPriority(.required, for: .vertical)
        l.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func configureFieldContainer(
        _ container: UIView,
        field: UIView,
        placeholder: UILabel
    ) {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = ValidState.border.color.cgColor

        placeholder.isUserInteractionEnabled = false

        container.addSubview(field)
        container.addSubview(placeholder)

        let height = container.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        height.priority = .defaultHigh
        height.isActive = true

        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            field.topAnchor.constraint(equalTo: container.topAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            placeholder.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            placeholder.topAnchor.constraint(equalTo: container.topAnchor, constant: 6)
        ])

        container.setContentHuggingPriority(.defaultHigh, for: .vertical)
        container.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private func configureFieldContainerWithAccessory(
        _ container: UIView,
        field: UIView,
        placeholder: UILabel,
        accessory: UIView,
        accessorySize: CGSize
    ) {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = ValidState.border.color.cgColor

        placeholder.isUserInteractionEnabled = false

        container.addSubview(field)
        container.addSubview(placeholder)
        container.addSubview(accessory)

        let height = container.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        height.priority = .defaultHigh
        height.isActive = true

        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            field.trailingAnchor.constraint(equalTo: accessory.leadingAnchor, constant: -8),
            field.topAnchor.constraint(equalTo: container.topAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            placeholder.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            placeholder.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),

            accessory.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            accessory.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            accessory.widthAnchor.constraint(equalToConstant: accessorySize.width),
            accessory.heightAnchor.constraint(equalToConstant: accessorySize.height)
        ])

        container.setContentHuggingPriority(.defaultHigh, for: .vertical)
        container.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    // MARK: Validation helpers
    private func isCardValid() -> Bool { Card.isCardNumberValid(cardNumberField.text?.formattedCardNumber()) }
    private func isExpValid()  -> Bool { Card.isExpDateValid(expiryField.expCardText?.formattedCardExp()) }
    private func isCvvValid()  -> Bool { Card.isValidCvv(cvv: cvvField.text?.formattedCardCVV(), isCvvRequired: isCvvRequired) }
    private func allValid() -> Bool { isCardValid() && isExpValid() && isCvvValid() }

    // MARK: Visual state
    private func applyVisualState() {
        let cardText = cardNumberField.text?.formattedCardNumber() ?? ""
        let expText  = expiryField.expCardText?.formattedCardExp() ?? ""
        let cvvText  = cvvField.text?.formattedCardCVV() ?? ""

        let cardError = cardTouched && !cardNumberField.isFirstResponder && !cardText.isEmpty && !isCardValid()
        let expError  = expTouched  && !expiryField.isFirstResponder     && !expText.isEmpty  && !isExpValid()
        let cvvError  = cvvTouched  && !cvvField.isFirstResponder        && !cvvText.isEmpty  && !isCvvValid()

        let focusedCard = cardNumberField.isFirstResponder
        let focusedExp  = expiryField.isFirstResponder
        let focusedCvv  = cvvField.isFirstResponder

        // CARD
        cardContainer.layer.borderColor =
            focusedCard ? ValidState.normal.color.cgColor :
            (cardError ? ValidState.error.color.cgColor : ValidState.border.color.cgColor)
        cardNumberField.textColor = cardError ? ValidState.error.color : ValidState.text.color
        cardPlaceholder.text      = cardError ? PlaceholderType.incorrectCard.toString() : PlaceholderType.correctCard.toString()
        cardPlaceholder.textColor = cardError ? ValidState.error.color : .secondaryLabel

        // EXP
        expiryContainer.layer.borderColor =
            focusedExp ? ValidState.normal.color.cgColor :
            (expError ? ValidState.error.color.cgColor : ValidState.border.color.cgColor)
        expiryField.textColor     = expError ? ValidState.error.color : ValidState.text.color
        expiryPlaceholder.text    = expError ? PlaceholderType.incorrectExpDate.toString() : PlaceholderType.correctExpDate.toString()
        expiryPlaceholder.textColor = expError ? ValidState.error.color : .secondaryLabel

        // CVV
        cvvContainer.layer.borderColor =
            focusedCvv ? ValidState.normal.color.cgColor :
            (cvvError ? ValidState.error.color.cgColor : ValidState.border.color.cgColor)
        cvvField.textColor        = cvvError ? ValidState.error.color : ValidState.text.color
        cvvPlaceholder.text       = cvvError ? PlaceholderType.incorrectCvv.toString() : PlaceholderType.correctCvv.toString()
        cvvPlaceholder.textColor  = cvvError ? ValidState.error.color : .secondaryLabel

        // Кнопка
        let enabled = allValid()
        if enabled && !cardFillFinishedSent {
            cardFillFinishedSent = true
            onCardDataFillFinished?()
        }
        payButton.isUserInteractionEnabled = enabled
        payButton.alpha = enabled ? 1 : 0.3
    }

    // MARK: TextFields targets
    private func configureTextFields() {
        [cardNumberField, expiryField, cvvField].forEach { tf in
            tf.addTarget(self, action: #selector(didBeginEditing(_:)), for: .editingDidBegin)
            tf.addTarget(self, action: #selector(didChange(_:)),       for: .editingChanged)
            tf.addTarget(self, action: #selector(didEndEditing(_:)),   for: .editingDidEnd)
        }
    }

    @objc private func didBeginEditing(_ tf: UITextField) {
        if tf === cardNumberField { cardTouched = true }
        if tf === expiryField     { expTouched  = true }
        if tf === cvvField        { cvvTouched  = true }
        applyVisualState()
    }

    @objc private func didChange(_ tf: UITextField) {
        if tf === cardNumberField {
            cardNumberField.text = cardNumberField.text?.formattedCardNumber()
            if !cardFillStartedSent {
                cardFillStartedSent = true
                onCardDataFillStarted?()
            }
            let clean = Card.cleanCreditCardNo(cardNumberField.text ?? "")
            updatePaymentSystemIcon(with: clean)
            scheduleBinLookupIfNeeded()
        } else if tf === expiryField {
            expiryField.expCardText = expiryField.text?.formattedCardExp()
            if !expiredDateEventSent, let exp = expiryField.text?.formattedCardExp(), Card.isExpDateValid(exp) {
                expiredDateEventSent = true
                onExpiredDateFilled?()
            }
        } else if tf === cvvField {
            cvvField.text = cvvField.text?.formattedCardCVV()
            if !cvvEventSent, let cvv = cvvField.text?.formattedCardCVV(), Card.isValidCvv(cvv: cvv, isCvvRequired: isCvvRequired) {
                cvvEventSent = true
                onCvvFilled?()
            }
            updateEyeIcon()
        }
        applyVisualState()
    }

    @objc private func didEndEditing(_ tf: UITextField) {
        applyVisualState()
        
        if tf === cardNumberField {
            let cardText = cardNumberField.text?.formattedCardNumber()
            if Card.isCardNumberValid(cardText) {
                onCardNumberCompleted?()
            }
        }
    }

    // MARK: Actions
    @objc private func payTapped() {
        onPayTapped?(cardNumberField.text ?? "", expiryField.text ?? "", cvvField.text ?? "")
    }

    // MARK: Helpers for accessories
    private func updatePaymentSystemIcon(with cardNumber: String?) {
        guard let num = cardNumber else { cardTypeIcon.isHidden = true; return }
        let type = Card.cardType(from: num)
        if type != .unknown {
            cardTypeIcon.image = type.getIcon()
            cardTypeIcon.isHidden = false
            if !cardTypeDefinitionSent || detectedCardType != type {
                cardTypeDefinitionSent = true
                detectedCardType = type
                onCardTypeDefined?(type)
            }
        } else {
            cardTypeIcon.isHidden = true
        }
    }

    @objc private func toggleCvvSecure() {
        guard let text = cvvField.text, !text.isEmpty else { return }
        
        cvvField.isSecureTextEntry.toggle()
        updateEyeIcon()
    }
    
    private func updateEyeIcon() {
        guard let text = cvvField.text, !text.isEmpty else {
            cvvEyeButton.setImage(EyeStatus.byDefault.image, for: .normal)
            return
        }
        
        let state: EyeStatus = cvvField.isSecureTextEntry ? .closed : .open
        cvvEyeButton.setImage(state.image, for: .normal)
    }
    
    // MARK: - BIN debounce
    private func scheduleBinLookupIfNeeded() {
        let clean = Card.cleanCreditCardNo(cardNumberField.text ?? "")
        
        if clean.count < 6 {
            cardNumberTimer?.invalidate()
            lastScheduledCleanCard = nil
            cvvContainer.isHidden = !isCvvRequired
            return
        }
        
        cardNumberTimer?.invalidate()
        lastScheduledCleanCard = clean
        cardNumberTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                               target: self,
                                               selector: #selector(sendBinRequest),
                                               userInfo: nil,
                                               repeats: false)
    }
    
    @objc private func sendBinRequest() {
        cardNumberTimer?.invalidate()
        
        guard let clean = lastScheduledCleanCard, clean.count >= 6 else { return }
    
        requestBinInfo?(clean) { [weak self] info in
            guard let self = self, let info = info else { return }
            
            self.cvvContainer.isHidden = info.hideCvvInput
            
            if let convertedAmount = info.convertedAmount, let currencyCode = info.currencyCode {
                let _ = Currency.getCurrencySign(code: currencyCode)
                self.setAmountText("\(convertedAmount) \(currencyCode)")
            }
        }
    }
}

extension PaymentCardContentViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {

        var touchedView: UIView? = touch.view

        while let currentView = touchedView {

            if currentView is UIControl {
                return false
            }

            touchedView = currentView.superview
        }

        return true
    }
}
