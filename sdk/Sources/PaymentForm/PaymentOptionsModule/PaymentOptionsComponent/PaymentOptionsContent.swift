//
//  PaymentOptionsContent.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

protocol BottomSheetPaymentOptionsSelectionButtonDelegate: AnyObject {
    func didSelect(method: PaymentOptionsViewController.ResolvedPaymentMethod)
    func patch(email: String?, tokenize: Bool)
}

final class BottomSheetPaymentOptionsContentViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let configuration: PaymentConfiguration
    private let methods: [PaymentOptionsViewController.ResolvedPaymentMethod]
    
    private var paymentButtons: [UIButton] = []
    
    private var displayedResolvedMethods: [PaymentOptionsViewController.ResolvedPaymentMethod] = []
    private var additionalResolvedMethods: [PaymentOptionsViewController.ResolvedPaymentMethod] = []
    
    private var resolvedByButtonTag: [Int: PaymentOptionsViewController.ResolvedPaymentMethod] = [:]
    
    private(set) var additionalMethods: [PaymentMethodType] = []
    private(set) var displayedMethods: [PaymentMethodType] = []
    
    private(set) var showAdditional = false
    
    private var emailFillEventSent = false
    private let additionalButtonID = "additionalButton"
    
    private var moreButton: UIView?
    
    var onContentChanged: (() -> Void)?
    
    // MARK: - Save card
    
    private var saveCardContainer: UIView?
    private(set) var saveCardSwitch: UISwitch?
    private var saveCardTooltip: TooltipView?
    
    private let saveCardState: IntentSaveCardState?
    private let tokenize: Bool?
    
    // MARK: - Email
    
    private var emailContainer: ReceiptEmailView?
    private(set) var receiptSwitch: UISwitch?
    
    private let emailBehavior: EmailBehaviorType
    private let email: String?
    
    // MARK: - Layout state
    
    private var forcedLandscapeLayout: Bool?
    private var lastAppliedLandscapeLayout: Bool?
    private var isRebuildingPaymentLayout = false
    
    private var isLandscapeLayout: Bool {
        if let forcedLandscapeLayout {
            return forcedLandscapeLayout
        }
        
        if let orientation = view.window?.windowScene?.interfaceOrientation {
            return orientation.isLandscape
        }
        
        return false
    }
    
    // MARK: - Delegate
    
    weak var delegate: BottomSheetPaymentOptionsSelectionButtonDelegate?
    
    // MARK: - UI
    
    private let handleView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Выберите способ оплаты"
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let paymentMethodsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let optionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(
            arrangedSubviews: [
                titleLabel,
                paymentMethodsStack,
                optionsStack
            ]
        )
        
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        return stack
    }()
    
    private let logoView: CloudPaymentsLogoView = {
        let view = CloudPaymentsLogoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Init
    
    init(
        methods: [PaymentOptionsViewController.ResolvedPaymentMethod],
        saveCardState: IntentSaveCardState?,
        tokenize: Bool?,
        emailBehavior: EmailBehaviorType,
        email: String?,
        configuration: PaymentConfiguration
    ) {
        self.configuration = configuration
        self.methods = methods
        self.saveCardState = saveCardState
        self.tokenize = tokenize
        self.emailBehavior = emailBehavior
        self.email = email
        
        super.init(
            nibName: nil,
            bundle: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Orientation
    
    override var shouldAutorotate: Bool {
        true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [
            .portrait,
            .landscapeLeft,
            .landscapeRight
        ]
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupLayout()
        prepareResolvedMethods()
        
        updateAdaptiveMetrics()
        rebuildPaymentMethodsLayout()
        configureSaveCardAndEmailBlocks()
        
        view.layoutIfNeeded()
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapOutside)
        )
        
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        restoreFromConfiguration()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        syncLayoutWithCurrentOrientation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updatePaymentButtonGradients()
        updateScrollForKeyboard()
        
        syncLayoutWithCurrentOrientation()
    }
    
    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(
            to: size,
            with: coordinator
        )
        
        let landscape =
        size.width > size.height
        
        forcedLandscapeLayout =
        landscape
        
        lastAppliedLandscapeLayout =
        landscape
        
        coordinator.animate(
            alongsideTransition: { [weak self] _ in
                guard let self else {
                    return
                }
                
                self.isRebuildingPaymentLayout = true
                
                self.updateAdaptiveMetrics()
                self.rebuildPaymentMethodsLayout()
                
                self.view.layoutIfNeeded()
                
                self.isRebuildingPaymentLayout = false
            },
            completion: { [weak self] _ in
                guard let self else {
                    return
                }
                
                self.forcedLandscapeLayout = nil
                
                self.updatePaymentButtonGradients()
                self.view.layoutIfNeeded()
                
                self.onContentChanged?()
            }
        )
    }
    
    // MARK: - Orientation sync
    
    private func syncLayoutWithCurrentOrientation() {
        guard !isRebuildingPaymentLayout else {
            return
        }
        
        guard let orientation =
                view.window?
            .windowScene?
            .interfaceOrientation else {
            return
        }
        
        let shouldUseLandscapeLayout =
        orientation.isLandscape
        
        guard lastAppliedLandscapeLayout != shouldUseLandscapeLayout else {
            return
        }
        
        lastAppliedLandscapeLayout =
        shouldUseLandscapeLayout
        
        isRebuildingPaymentLayout =
        true
        
        forcedLandscapeLayout =
        shouldUseLandscapeLayout
        
        updateAdaptiveMetrics()
        rebuildPaymentMethodsLayout()
        
        forcedLandscapeLayout =
        nil
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        updatePaymentButtonGradients()
        
        isRebuildingPaymentLayout =
        false
        
        onContentChanged?()
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(handleView)
        contentView.addSubview(mainStack)
        contentView.addSubview(logoView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            
            scrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            
            scrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            
            scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            
            contentView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor
            ),
            
            contentView.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor
            ),
            
            contentView.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor
            ),
            
            contentView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor
            ),
            
            contentView.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor
            ),
            
            handleView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 20
            ),
            
            handleView.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor
            ),
            
            handleView.widthAnchor.constraint(
                equalToConstant: 136
            ),
            
            handleView.heightAnchor.constraint(
                equalToConstant: 4
            ),
            
            mainStack.topAnchor.constraint(
                equalTo: handleView.bottomAnchor,
                constant: 20
            ),
            
            mainStack.leadingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            
            mainStack.trailingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
            
            logoView.topAnchor.constraint(
                equalTo: mainStack.bottomAnchor,
                constant: 20
            ),
            
            logoView.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor
            ),
            
            logoView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -20
            )
        ])
    }
    
    // MARK: - Adaptive layout
    
    private func updateAdaptiveMetrics() {
        if isLandscapeLayout {
            titleLabel.font = .systemFont(
                ofSize: 18,
                weight: .semibold
            )
            
            mainStack.spacing = 12
            paymentMethodsStack.spacing = 12
            optionsStack.spacing = 12
            
        } else {
            titleLabel.font = .systemFont(
                ofSize: 22,
                weight: .semibold
            )
            
            mainStack.spacing = 16
            paymentMethodsStack.spacing = 16
            optionsStack.spacing = 16
        }
    }
    
    // MARK: - Methods preparation
    
    private func prepareResolvedMethods() {
        displayedMethods.removeAll()
        additionalMethods.removeAll()
        
        displayedResolvedMethods.removeAll()
        additionalResolvedMethods.removeAll()
        
        if methods.count <= 3 {
            displayedResolvedMethods =
            methods
            
            displayedMethods =
            methods.map {
                $0.displayType
            }
            
            return
        }
        
        for (index, resolved) in methods.enumerated() {
            if index < 2 {
                displayedResolvedMethods.append(
                    resolved
                )
                
                displayedMethods.append(
                    resolved.displayType
                )
            } else {
                additionalResolvedMethods.append(
                    resolved
                )
                
                additionalMethods.append(
                    resolved.displayType
                )
            }
        }
    }
    
    // MARK: - Rebuild methods
    
    private func rebuildPaymentMethodsLayout() {
        clearPaymentMethodsLayout()
        
        paymentButtons.removeAll()
        resolvedByButtonTag.removeAll()
        
        moreButton = nil
        
        var methodViews: [UIView] = []
        
        for resolved in displayedResolvedMethods {
            let button =
            makeButton(
                for: resolved
            )
            
            methodViews.append(
                button
            )
        }
        
        if showAdditional {
            for resolved in additionalResolvedMethods {
                let button =
                makeButton(
                    for: resolved
                )
                
                button.accessibilityIdentifier =
                additionalButtonID
                
                methodViews.append(
                    button
                )
            }
        }
        
        if isLandscapeLayout {
            buildLandscapePaymentMethods(
                views: methodViews
            )
        } else {
            buildPortraitPaymentMethods(
                views: methodViews
            )
        }
        
        if !additionalResolvedMethods.isEmpty {
            if showAdditional {
                let collapseButton =
                makeCollapseButton()
                
                collapseButton.accessibilityIdentifier =
                additionalButtonID
                
                paymentMethodsStack.addArrangedSubview(
                    collapseButton
                )
                
                moreButton =
                collapseButton
            } else {
                let moreView =
                makeMoreMethodsView(
                    for: additionalResolvedMethods
                )
                
                moreView.accessibilityIdentifier =
                additionalButtonID
                
                paymentMethodsStack.addArrangedSubview(
                    moreView
                )
                
                moreButton = moreView
            }
        }
        
        view.setNeedsLayout()
    }
    
    private func clearPaymentMethodsLayout() {
        for view in paymentMethodsStack.arrangedSubviews {
            paymentMethodsStack.removeArrangedSubview(
                view
            )
            
            view.removeFromSuperview()
        }
    }
    
    // MARK: - Portrait
    
    private func buildPortraitPaymentMethods(
        views: [UIView]
    ) {
        paymentMethodsStack.axis = .vertical
        paymentMethodsStack.spacing = 16
        paymentMethodsStack.alignment = .fill
        paymentMethodsStack.distribution = .fill
        
        for view in views {
            paymentMethodsStack.addArrangedSubview(
                view
            )
        }
    }
    
    // MARK: - Landscape
    
    private func buildLandscapePaymentMethods(
        views: [UIView]
    ) {
        paymentMethodsStack.axis = .vertical
        paymentMethodsStack.spacing = 12
        paymentMethodsStack.alignment = .fill
        paymentMethodsStack.distribution = .fill
        
        var index = 0
        
        while index < views.count {
            let leftView =
            views[index]
            
            let rightView: UIView
            
            if index + 1 < views.count {
                rightView =
                views[index + 1]
            } else {
                rightView =
                UIView()
            }
            
            let row =
            UIStackView(
                arrangedSubviews: [
                    leftView,
                    rightView
                ]
            )
            
            row.axis =
                .horizontal
            
            row.spacing =
            12
            
            row.alignment =
                .fill
            
            row.distribution =
                .fillEqually
            
            row.heightAnchor
                .constraint(equalToConstant: 56)
                .isActive = true
            
            paymentMethodsStack.addArrangedSubview(
                row
            )
            
            index += 2
        }
    }
    
    // MARK: - Save card + Email
    
    private func configureSaveCardAndEmailBlocks() {
        clearOptionsStack()
        
        if let saveCardState {
            setupSaveCardUI(
                state: saveCardState,
                isSelected: tokenize ?? false
            )
        }
        
        let receiptView =
        makeReceiptSwitchAndEmailView()
        
        optionsStack.addArrangedSubview(
            receiptView
        )
    }
    
    private func clearOptionsStack() {
        for view in optionsStack.arrangedSubviews {
            optionsStack.removeArrangedSubview(
                view
            )
            
            view.removeFromSuperview()
        }
        
        saveCardContainer = nil
        saveCardSwitch = nil
        
        emailContainer = nil
        receiptSwitch = nil
    }
    
    // MARK: - Payment button
    
    private func makeButton(
        for resolved: PaymentOptionsViewController.ResolvedPaymentMethod
    ) -> UIButton {
        let type = resolved.displayType
        
        var config = UIButton.Configuration.filled()
        
        config.cornerStyle = .fixed
        config.background.cornerRadius = 8
        
        config.title = type.buttonTitle
        config.image = type.buttonIcon
        
        config.imagePadding = 8
        config.imagePlacement = .leading
        
        config.baseBackgroundColor =
        type.backgroundColor
        
        let button = UIButton(
            configuration: config
        )
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.heightAnchor
            .constraint(equalToConstant: 56)
            .isActive = true
        
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        
        if type == .tInstallment {
            button.configurationUpdateHandler = { btn in
                guard var updatedConfig =
                        btn.configuration else {
                    return
                }
                
                updatedConfig.attributedTitle =
                AttributedString(
                    type.buttonTitle ?? "",
                    attributes: AttributeContainer([
                        .foregroundColor:
                            UIColor(
                                red: 51 / 255,
                                green: 51 / 255,
                                blue: 51 / 255,
                                alpha: 1
                            ),
                        
                            .font:
                            UIFont.systemFont(
                                ofSize: 16,
                                weight: .semibold
                            )
                    ])
                )
                
                btn.configuration =
                updatedConfig
            }
        }
        
        if type == .dr {
            button.configurationUpdateHandler = { btn in
                guard var updatedConfig =
                        btn.configuration else {
                    return
                }
                
                updatedConfig.attributedTitle =
                AttributedString(
                    type.buttonTitle ?? "",
                    attributes: AttributeContainer([
                        .foregroundColor:
                            UIColor(
                                red: 34 / 255,
                                green: 45 / 255,
                                blue: 65 / 255,
                                alpha: 1
                            ),
                        
                            .font:
                            UIFont.systemFont(
                                ofSize: 16,
                                weight: .regular
                            )
                    ])
                )
                
                btn.configuration =
                updatedConfig
            }
        }
        
        if type == .foreignCard {
            button.contentHorizontalAlignment =
                .center
            
            button.semanticContentAttribute =
                .forceRightToLeft
            
            let gradient = CAGradientLayer()
            
            gradient.name =
            "foreignCardGradient"
            
            gradient.colors = [
                UIColor(
                    red: 46 / 255,
                    green: 113 / 255,
                    blue: 252 / 255,
                    alpha: 1
                ).cgColor,
                
                UIColor(
                    red: 93 / 255,
                    green: 23 / 255,
                    blue: 196 / 255,
                    alpha: 1
                ).cgColor
            ]
            
            gradient.startPoint =
            CGPoint(
                x: 0,
                y: 0.5
            )
            
            gradient.endPoint =
            CGPoint(
                x: 1,
                y: 0.5
            )
            
            gradient.cornerRadius = 8
            
            button.layer.insertSublayer(
                gradient,
                at: 0
            )
        }
        
        let tag =
        resolvedByButtonTag.count + 1
        
        button.tag = tag
        
        resolvedByButtonTag[tag] =
        resolved
        
        button.addTarget(
            self,
            action: #selector(paymentButtonTapped(_:)),
            for: .touchUpInside
        )
        
        paymentButtons.append(
            button
        )
        
        print(
            "Создали кнопку: type = \(type.rawValue)"
        )
        
        return button
    }
    
    // MARK: - Gradient
    
    private func updatePaymentButtonGradients() {
        for button in paymentButtons {
            guard let gradient =
                    button.layer.sublayers?
                .first(
                    where: {
                        $0.name == "foreignCardGradient"
                    }
                ) as? CAGradientLayer else {
                continue
            }
            
            gradient.frame = button.bounds
            gradient.cornerRadius = 8
        }
    }
    
    // MARK: - Additional icons
    
    private func makeIconsStack(
        for methods: [PaymentOptionsViewController.ResolvedPaymentMethod]
    ) -> UIView {
        let container = UIView()
        
        var previousView: UIImageView?
        
        for resolved in methods {
            let type = resolved.displayType
            
            let imageView = UIImageView()
            
            imageView.translatesAutoresizingMaskIntoConstraints =
            false
            
            imageView.image =
            type.additionalButtonIcon
            
            imageView.contentMode =
                .scaleAspectFill
            
            imageView.widthAnchor
                .constraint(equalToConstant: 40)
                .isActive = true
            
            imageView.heightAnchor
                .constraint(equalToConstant: 40)
                .isActive = true
            
            container.addSubview(
                imageView
            )
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(
                    equalTo: container.topAnchor
                ),
                
                imageView.bottomAnchor.constraint(
                    equalTo: container.bottomAnchor
                )
            ])
            
            if let previousView {
                imageView.leadingAnchor
                    .constraint(
                        equalTo: previousView.trailingAnchor,
                        constant: -8
                    )
                    .isActive = true
                
                container.insertSubview(
                    imageView,
                    belowSubview: previousView
                )
                
            } else {
                imageView.leadingAnchor
                    .constraint(
                        equalTo: container.leadingAnchor
                    )
                    .isActive = true
            }
            
            previousView = imageView
        }
        
        if let previousView {
            previousView.trailingAnchor
                .constraint(
                    equalTo: container.trailingAnchor
                )
                .isActive = true
        }
        
        return container
    }
    
    // MARK: - More methods
    
    private func makeMoreMethodsView(
        for methods: [PaymentOptionsViewController.ResolvedPaymentMethod]
    ) -> UIView {
        let view = UIView()
        
        view.backgroundColor = .white
        
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        
        view.layer.borderColor =
        UIColor.colorBlue.cgColor
        
        view.heightAnchor
            .constraint(equalToConstant: 56)
            .isActive = true
        
        view.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(toggleAdditional)
        )
        
        view.addGestureRecognizer(
            tap
        )
        
        let label = UILabel()
        
        label.text =
        "Другие способы"
        
        label.textColor =
            .colorBlue
        
        label.font =
            .systemFont(ofSize: 17)
        
        label.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )
        
        let iconsStack =
        makeIconsStack(
            for: methods
        )
        
        let spacer = UIView()
        
        let container = UIStackView(
            arrangedSubviews: [
                label,
                spacer,
                iconsStack
            ]
        )
        
        container.axis = .horizontal
        container.spacing = 8
        container.alignment = .center
        
        container.translatesAutoresizingMaskIntoConstraints =
        false
        
        view.addSubview(
            container
        )
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 16
            ),
            
            container.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -12
            ),
            
            container.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            
            container.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
        
        return view
    }
    
    // MARK: - Collapse
    
    private func makeCollapseButton() -> UIButton {
        var config =
        UIButton.Configuration.plain()
        
        config.title =
        "Свернуть"
        
        config.baseForegroundColor =
            .systemBlue
        
        config.background.backgroundColor =
            .clear
        
        let button = UIButton(
            configuration: config
        )
        
        button.heightAnchor
            .constraint(equalToConstant: 32)
            .isActive = true
        
        button.layer.borderWidth = 1
        
        button.layer.borderColor =
        UIColor.systemBlue.cgColor
        
        button.layer.cornerRadius = 8
        
        button.addTarget(
            self,
            action: #selector(toggleAdditional),
            for: .touchUpInside
        )
        
        return button
    }
    
    // MARK: - Toggle additional
    
    @objc private func toggleAdditional() {
        showAdditional.toggle()
        
        UIView.performWithoutAnimation {
            rebuildPaymentMethodsLayout()
            view.layoutIfNeeded()
        }
        
        onContentChanged?()
        
        if !isKeyboardShowing {
            UIView.animate(
                withDuration: 0.25
            ) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Receipt
    
    private func makeReceiptSwitchAndEmailView() -> UIStackView {
        let label = UILabel()
        
        label.text =
        "Отправить квитанцию на E-mail"
        
        label.font =
            .systemFont(ofSize: 15)
        
        label.textColor =
            .label
        
        label.numberOfLines = 1
        
        label.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        
        let toggle = UISwitch()
        
        toggle.onTintColor =
            .colorBlue
        
        toggle.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )
        
        let emailView =
        ReceiptEmailView()
        
        emailView.translatesAutoresizingMaskIntoConstraints =
        false
        
        emailView.emailBehavior =
        emailBehavior
        
        emailView.email =
        email
        
        emailView.isReceiptSwitchOn = {
            [weak toggle] in
            
            toggle?.isOn ?? false
        }
        
        emailView.setButtonsEnabled = {
            [weak self] enabled in
            
            self?.updateButtonsEnabled(
                enabled
            )
        }
        
        emailContainer =
        emailView
        
        receiptSwitch =
        toggle
        
        let spacer =
        UIView()
        
        let toggleRow =
        UIStackView(
            arrangedSubviews: [
                label,
                spacer,
                toggle
            ]
        )
        
        toggleRow.axis =
            .horizontal
        
        toggleRow.spacing = 8
        
        toggleRow.alignment =
            .center
        
        let stack =
        UIStackView(
            arrangedSubviews: [
                toggleRow
            ]
        )
        
        stack.axis =
            .vertical
        
        stack.spacing =
        8
        
        switch emailBehavior {
        case .required:
            toggle.isHidden = true
            
            stack.addArrangedSubview(
                emailView
            )
            
            emailView.validateEmail(
                email
            )
            
        case .optional:
            if let email,
               !email.isEmpty {
                
                toggle.isOn = true
                
                stack.addArrangedSubview(
                    emailView
                )
                
                emailView.validateEmail(
                    email
                )
            }
            
        case .hidden:
            toggleRow.isHidden = true
        }
        
        toggle.addTarget(
            self,
            action: #selector(receiptSwitchChanged(_:)),
            for: .valueChanged
        )
        
        return stack
    }
    
    @objc private func receiptSwitchChanged(
        _ sender: UISwitch
    ) {
        let context =
        sender.isOn
        ? "On"
        : "Off"
        
        AnalyticsService.shared.sendActionClickEvent(
            configuration: configuration,
            elementLabel: "SendEmail",
            elementType: "Checkbox",
            actionType: "Click",
            screenName: "/methods",
            actionContext: context
        )
        
        guard
            let emailView = emailContainer,
            let stack =
                sender.superview?
                .superview as? UIStackView
        else {
            return
        }
        
        if sender.isOn {
            if !stack.arrangedSubviews.contains(
                emailView
            ) {
                stack.addArrangedSubview(
                    emailView
                )
            }
            
            emailView.validateEmail(
                emailView.email
            )
            
        } else {
            stack.removeArrangedSubview(
                emailView
            )
            
            emailView.removeFromSuperview()
            
            updateButtonsEnabled(
                true
            )
        }
        
        onContentChanged?()
        
        if !isKeyboardShowing {
            UIView.animate(
                withDuration: 0.25
            ) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Save card
    
    private func setupSaveCardUI(
        state: IntentSaveCardState,
        isSelected: Bool
    ) {
        saveCardContainer?
            .removeFromSuperview()
        
        saveCardTooltip?
            .removeFromSuperview()
        
        saveCardTooltip = nil
        
        switch state {
        case .optional:
            let container =
            UIView()
            
            container.translatesAutoresizingMaskIntoConstraints =
            false
            
            let label =
            UILabel()
            
            label.translatesAutoresizingMaskIntoConstraints =
            false
            
            label.text =
            "Сохранить данные карты или счёта"
            
            label.font =
                .systemFont(ofSize: 15)
            
            label.textColor =
                .label
            
            label.numberOfLines =
            1
            
            label.lineBreakMode =
                .byTruncatingTail
            
            label.adjustsFontSizeToFitWidth =
            true
            
            label.minimumScaleFactor =
            0.8
            
            let infoButton =
            UIButton(type: .custom)
            
            infoButton.translatesAutoresizingMaskIntoConstraints =
            false
            
            infoButton.setImage(
                .icn_attention,
                for: .normal
            )
            
            infoButton.addTarget(
                self,
                action: #selector(showTooltip),
                for: .touchUpInside
            )
            
            let toggle =
            UISwitch()
            
            toggle.translatesAutoresizingMaskIntoConstraints =
            false
            
            toggle.isOn =
            isSelected
            
            toggle.onTintColor =
                .colorBlue
            
            saveCardSwitch =
            toggle
            
            container.addSubview(
                label
            )
            
            container.addSubview(
                infoButton
            )
            
            container.addSubview(
                toggle
            )
            
            NSLayoutConstraint.activate([
                container.heightAnchor.constraint(
                    equalToConstant: 31
                ),
                
                toggle.trailingAnchor.constraint(
                    equalTo: container.trailingAnchor
                ),
                
                toggle.centerYAnchor.constraint(
                    equalTo: container.centerYAnchor
                ),
                
                label.leadingAnchor.constraint(
                    equalTo: container.leadingAnchor
                ),
                
                label.centerYAnchor.constraint(
                    equalTo: container.centerYAnchor
                ),
                
                infoButton.leadingAnchor.constraint(
                    equalTo: label.trailingAnchor,
                    constant: 4
                ),
                
                infoButton.centerYAnchor.constraint(
                    equalTo: container.centerYAnchor
                ),
                
                infoButton.widthAnchor.constraint(
                    equalToConstant: 24
                ),
                
                infoButton.heightAnchor.constraint(
                    equalToConstant: 24
                ),
                
                infoButton.trailingAnchor.constraint(
                    lessThanOrEqualTo: toggle.leadingAnchor,
                    constant: -8
                )
            ])
            
            label.setContentCompressionResistancePriority(
                .defaultLow,
                for: .horizontal
            )
            
            label.setContentHuggingPriority(
                .defaultLow,
                for: .horizontal
            )
            
            infoButton.setContentCompressionResistancePriority(
                .required,
                for: .horizontal
            )
            
            infoButton.setContentHuggingPriority(
                .required,
                for: .horizontal
            )
            
            toggle.setContentCompressionResistancePriority(
                .required,
                for: .horizontal
            )
            
            toggle.setContentHuggingPriority(
                .required,
                for: .horizontal
            )
            
            optionsStack.addArrangedSubview(
                container
            )
            
            saveCardContainer =
            container
            
        case .force:
            let container =
            UIStackView()
            
            container.axis =
                .horizontal
            
            container.spacing =
            8
            
            container.alignment =
                .center
            
            container.distribution =
                .fill
            
            let label =
            UILabel()
            
            label.text =
            "При оплате данные карты сохранятся"
            
            label.font =
                .systemFont(ofSize: 15)
            
            label.textColor =
                .label
            
            label.numberOfLines =
            1
            
            label.adjustsFontSizeToFitWidth =
            true
            
            label.minimumScaleFactor =
            0.8
            
            let infoButton =
            UIButton(type: .system)
            
            infoButton.setImage(
                .icn_attention,
                for: .normal
            )
            
            infoButton.addTarget(
                self,
                action: #selector(showTooltip),
                for: .touchUpInside
            )
            
            container.addArrangedSubview(
                label
            )
            
            container.addArrangedSubview(
                UIView()
            )
            
            container.addArrangedSubview(
                infoButton
            )
            
            optionsStack.addArrangedSubview(
                container
            )
            
            saveCardContainer =
            container
            
        case .classic, .new:
            break
        }
    }
    
    // MARK: - Tooltip
    
    @objc private func showTooltip() {
        if let tooltip =
            saveCardTooltip {
            
            tooltip.removeFromSuperview()
            
            saveCardTooltip =
            nil
            
            return
        }
        
        let tooltip =
        TooltipView(
            texts: [
                    """
                    После оплаты карта сохранится.
                    В следующий раз вам не понадобится
                    вводить данные карты.
                    """,
                    
                    "Это удобно и экономит время."
            ]
        )
        
        view.addSubview(
            tooltip
        )
        
        tooltip.translatesAutoresizingMaskIntoConstraints =
        false
        
        guard let container =
                saveCardContainer else {
            return
        }
        
        view.layoutIfNeeded()
        
        let containerFrame =
        container.convert(
            container.bounds,
            to: view
        )
        
        NSLayoutConstraint.activate([
            tooltip.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: containerFrame.minX
            ),
            
            tooltip.widthAnchor.constraint(
                equalToConstant: containerFrame.width
            ),
            
            tooltip.bottomAnchor.constraint(
                equalTo: view.topAnchor,
                constant: containerFrame.minY - 16
            )
        ])
        
        saveCardTooltip =
        tooltip
    }
    
    // MARK: - Enable / Disable
    
    private func updateButtonsEnabled(
        _ enabled: Bool
    ) {
        for button in paymentButtons {
            button.isUserInteractionEnabled =
            enabled
            
            button.alpha =
            enabled
            ? 1
            : 0.3
        }
        
        moreButton?
            .isUserInteractionEnabled =
        enabled
        
        moreButton?
            .alpha =
        enabled
        ? 1
        : 0.3
        
        saveCardSwitch?
            .isEnabled =
        enabled
        
        receiptSwitch?
            .isEnabled =
        enabled
    }
    
    // MARK: - Payment button tapped
    
    @objc private func paymentButtonTapped(
        _ sender: UIButton
    ) {
        guard let resolved =
                resolvedByButtonTag[
                    sender.tag
                ] else {
            return
        }
        
        let methodType =
        resolved.displayType
        
        print(
            "Нажата кнопка: \(methodType.rawValue)"
        )
        
        sender.startLoading(
            loaderImage: .ic_button_logo
        )
        
        if !emailFillEventSent,
           let emailView = emailContainer,
           let email = emailView.email,
           emailView.isEmailValid() {
            
            AnalyticsService.shared.sendActionClickEvent(
                configuration: configuration,
                elementLabel: "Email",
                elementType: "Input",
                actionType: "Fill",
                screenName: "/methods",
                methodChosen: methodType.rawValue,
                actionContext: email
            )
            
            emailFillEventSent =
            true
        }
        
        delegate?
            .didSelect(
                method: resolved
            )
        
        let currentEmail =
        emailContainer?.email
        
        let tokenize =
        saveCardSwitch?
            .isOn
        ?? false
        
        delegate?
            .patch(
                email: currentEmail,
                tokenize: tokenize
            )
        
        sender.stopLoading(
            title: methodType.buttonTitle,
            icon: methodType.buttonIcon,
            backgroundColor:
                methodType.backgroundColor
            ?? .white
        )
    }
    
    // MARK: - Keyboard
    
    private func updateScrollForKeyboard() {
        let keyboardHeight =
        isKeyboardShowing
        ? keyboardFrame.height
        : 0
        
        UIView.animate(
            withDuration: 0.25
        ) {
            self.scrollView.contentInset.bottom =
            keyboardHeight + 16
            
            self.scrollView.verticalScrollIndicatorInsets.bottom =
            keyboardHeight
        }
    }
    
    // MARK: - Tap outside
    
    @objc private func didTapOutside() {
        view.endEditing(
            true
        )
    }
    
    // MARK: - Restore
    
    private func restoreFromConfiguration() {
        let paymentData =
        configuration.paymentData
        
        if paymentData.isAdditionalMethodsExpanded == true,
           !showAdditional {
            
            toggleAdditional()
        }
        
        if let saveCard =
            paymentData.isSaveCardSelected {
            
            saveCardSwitch?
                .isOn =
            saveCard
        }
        
        if let receipt =
            paymentData.isReceiptSelected {
            
            receiptSwitch?
                .isOn =
            receipt
            
            if let toggle =
                receiptSwitch {
                
                receiptSwitchChanged(
                    toggle
                )
            }
        }
    }
}
