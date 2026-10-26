//
//  PaymentOptionsViewController.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

public final class PaymentOptionsViewController: BaseViewController {
    
    enum ResolvedPaymentMethodKind {
        case regular
        case cardForeign
    }
    
    struct ResolvedPaymentMethod {
        let method: PaymentMethod
        let displayType: PaymentMethodType
        let kind: ResolvedPaymentMethodKind
    }
    
    private let loaderView = LoaderView()
    private let configuration: PaymentConfiguration
    private let viewModel: BottomSheetPaymentOptionsViewModel
    private let skipLoader: Bool
    
    init(configuration: PaymentConfiguration, skipLoader: Bool = false) {
        self.configuration = configuration
        self.skipLoader = skipLoader
        self.viewModel = BottomSheetPaymentOptionsViewModel(configuration: configuration)
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Present
    
    @discardableResult
    public class func present(
        with configuration: PaymentConfiguration,
        from presentingViewController: UIViewController,
        skipLoader: Bool = false,
        completion: (() -> ())? = nil
    ) -> PaymentOptionsViewController {
        let controller = PaymentOptionsViewController(configuration: configuration, skipLoader: skipLoader)
        presentingViewController.present(controller, animated: true) {
            completion?()
        }
        
        if !configuration.paymentData.analyticsSessionStarted {
            AnalyticsService.shared.startSession()
            AnalyticsService.shared.sendScreenOpenedEvent(
                configuration: configuration,
                screenName: "PreStart",
                cardFieldsCount: 0,
                eventType: "Open"
            )
            configuration.paymentData.analyticsSessionStarted = true
        }
        
        return controller
    }
    
    public override func loadView() {
        super.loadView()
        if !skipLoader {
            view.addSubview(loaderView)
            loaderView.frame = view.bounds
            loaderView.fullConstraint()
            loaderView.isHidden = true
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if skipLoader,
           let methods = configuration.paymentData.cachedMethods,
           !methods.isEmpty {
            presentOptions(methods: methods, paymentMethodSequence: nil, intent: nil)
        } else {
            showLoading()
        }
        
        LoggerService.shared.startLogging(publicId: configuration.publicId)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if configuration.singlePaymentMode == nil {
            configuration.paymentUIDelegate.paymentFormWillDisplay()
            configuration.paymentUIDelegate.paymentFormDidDisplay()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if configuration.singlePaymentMode == nil {
            configuration.paymentUIDelegate.paymentFormWillHide()
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if configuration.singlePaymentMode == nil {
            configuration.paymentUIDelegate.paymentFormDidHide()
        }
    }
    
    // MARK: - Loader
    
    private func showLoading() {
        loaderView(isOn: true) {
            self.viewModel.loadPublicKeyAndCreateIntent { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    
                    switch result {
                    case .success(let (methods, paymentMethodSequence, intent)):
                        self.loaderView(isOn: false) {
                            self.presentOptions(
                                methods: methods,
                                paymentMethodSequence: paymentMethodSequence,
                                intent: intent
                            )
                        }
                        
                    case .failure:
                        self.loaderView(isOn: false) {
                            AnalyticsService.shared.sendScreenOpenedEvent(
                                configuration: self.configuration,
                                screenName: "/static-error",
                                cardFieldsCount: 0,
                                eventType: "Open"
                            )
                            self.showAlert(title: .errorWord, message: .errorConfiguration) {
                                self.dismiss(animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func resolveMethods(
        from methods: [PaymentMethod],
        paymentMethodSequence: [String]?
    ) -> [ResolvedPaymentMethod] {
        let hasAlternativeForeignCard = methods.contains {
            ($0.type ?? "") == PaymentMethodType.foreignCard.rawValue
        }
        
        let cardMethod = methods.first {
            ($0.type ?? "") == PaymentMethodType.card.rawValue
        }
        
        let sequence: [String]
        if let paymentMethodSequence, !paymentMethodSequence.isEmpty {
            sequence = paymentMethodSequence
        } else {
            sequence = configuration.paymentMethodSequence.map(\.rawValue)
        }
        
        var resolved: [ResolvedPaymentMethod] = []
        var usedTypes = Set<String>()
        
        func appendCardIfNeeded() {
            guard let cardMethod else {
                return
            }
            
            guard !usedTypes.contains(PaymentMethodType.card.rawValue) else {
                return
            }
            
            resolved.append(
                ResolvedPaymentMethod(
                    method: cardMethod,
                    displayType: .card,
                    kind: .regular
                )
            )
            usedTypes.insert(PaymentMethodType.card.rawValue)
            
            if cardMethod.isForeignCardEnabled == true && !hasAlternativeForeignCard {
                resolved.append(
                    ResolvedPaymentMethod(
                        method: cardMethod,
                        displayType: .foreignCard,
                        kind: .cardForeign
                    )
                )
            }
        }
        
        func appendAlternativeForeignCardIfNeeded() {
            guard !usedTypes.contains(PaymentMethodType.foreignCard.rawValue) else {
                return
            }
            
            guard let method = methods.first(where: { ($0.type ?? "") == PaymentMethodType.foreignCard.rawValue }) else {
                return
            }
            
            resolved.append(
                ResolvedPaymentMethod(
                    method: method,
                    displayType: .foreignCard,
                    kind: .regular
                )
            )
            usedTypes.insert(PaymentMethodType.foreignCard.rawValue)
        }
        
        for rawType in sequence {
            guard let type = PaymentMethodType(rawValue: rawType) else {
                continue
            }
            
            switch type {
            case .card:
                appendCardIfNeeded()
                
            case .foreignCard:
                appendAlternativeForeignCardIfNeeded()
                
            default:
                guard !usedTypes.contains(rawType) else {
                    continue
                }
                
                guard let method = methods.first(where: { ($0.type ?? "") == rawType }) else {
                    continue
                }
                
                resolved.append(
                    ResolvedPaymentMethod(
                        method: method,
                        displayType: type,
                        kind: .regular
                    )
                )
                usedTypes.insert(rawType)
            }
        }
        
        for method in methods {
            guard let rawType = method.type,
                  let type = PaymentMethodType(rawValue: rawType) else {
                continue
            }
            
            guard !usedTypes.contains(rawType) else {
                continue
            }
            
            switch type {
            case .card:
                appendCardIfNeeded()
                
            case .foreignCard:
                appendAlternativeForeignCardIfNeeded()
                
            default:
                resolved.append(
                    ResolvedPaymentMethod(
                        method: method,
                        displayType: type,
                        kind: .regular
                    )
                )
                usedTypes.insert(rawType)
            }
        }
        
        print("Итоговое количество кнопок: \(resolved.count)")
        return resolved
    }
    
    private func presentOptions(
        methods: [PaymentMethod],
        paymentMethodSequence: [String]?,
        intent: PaymentIntentResponse?
    ) {
        let resolvedMethods = resolveMethods(
            from: methods,
            paymentMethodSequence: paymentMethodSequence
        )
        
        if let singleMode = configuration.singlePaymentMode {
            
            if singleMode == .card {
                let hasCard = resolvedMethods.contains { $0.displayType == .card }
                let hasForeignCard = resolvedMethods.contains { $0.displayType == .foreignCard }
                
                if hasCard && hasForeignCard {
                    showOptionsScreen(methods: resolvedMethods, intent: intent)
                    return
                }
            }
            
            guard let resolved = resolvedMethods.first(where: { $0.displayType.rawValue == singleMode.rawValue }) else {
                if configuration.showResultScreenForSinglePaymentMode {
                    showAlert(title: .errorWord, message: .errorConfiguration) {
                        self.dismiss(animated: true)
                    }
                } else {
                    self.dismiss(animated: true)
                }
                return
            }
            
            launchResolvedMethod(resolved)
            return
        }
        
        if resolvedMethods.count == 1, let single = resolvedMethods.first {
            launchResolvedMethod(single)
        } else {
            showOptionsScreen(methods: resolvedMethods, intent: intent)
        }
    }
    
    private func launchResolvedMethod(_ resolved: ResolvedPaymentMethod) {
        
        switch resolved.displayType {
        case .card:
            launchDirectFlowCard(for: resolved)
            
        case .foreignCard:
            switch resolved.kind {
            case .cardForeign:
                launchDirectFlowCard(for: resolved)
            case .regular:
                launchDirectFlowOtherMethods(for: resolved)
            }
        case .sbp:
            launchDirectFlowSbp(for: resolved.method)
        case .tInstallment:
            launchTInstallmentFlow()
        default:
            launchDirectFlowOtherMethods(for: resolved)
        }
    }
    
    private func showOptionsScreen(methods: [ResolvedPaymentMethod], intent: PaymentIntentResponse?) {
        let viewModel = BottomSheetViewModel(cornerRadius: 20)
        let saveCardState = configuration.paymentData.intentSaveCardState
        let savedTokenize = configuration.paymentData.savedTokenize ?? false
        let emailBehavior = configuration.emailBehavior
        let email = configuration.paymentData.email
        
        let contentVC = BottomSheetPaymentOptionsContentViewController(
            methods: methods,
            saveCardState: saveCardState,
            tokenize: savedTokenize,
            emailBehavior: emailBehavior,
            email: email,
            configuration: configuration
        )
        
        contentVC.delegate = self
        contentVC.onContentChanged = { [weak self] in
            guard let self else { return }
            self.configuration.paymentData.isAdditionalMethodsExpanded = contentVC.showAdditional
            self.configuration.paymentData.isSaveCardSelected = contentVC.saveCardSwitch?.isOn
            self.configuration.paymentData.isReceiptSelected = contentVC.receiptSwitch?.isOn
        }
        
        let sheet = BottomSheetController(viewModel: viewModel, content: contentVC)
        sheet.present(in: self)
        
        if let intent {
            let displayedMethods = contentVC.displayedMethods.map { $0.rawValue }
            let methodsAvailable = (contentVC.displayedMethods + contentVC.additionalMethods).map { $0.rawValue }
            configuration.paymentData.methodsAvailable = methodsAvailable
            
            AnalyticsService.shared.sendScreenOpenedEvent(
                configuration: configuration,
                screenName: "Start",
                methodsAvailable: methodsAvailable,
                cardFieldsCount: 0,
                eventType: "Open"
            )
            
            AnalyticsService.shared.sendPaymentMethodsStartSessionEvent(
                configuration: configuration,
                intent: intent,
                methodsAvailable: methodsAvailable,
                displayedMethods: displayedMethods
            )
        }
        
        sheet.onDismiss = { [weak self] isSwipe in
            guard let self else { return }
            if isSwipe {
                AnalyticsService.shared.sendActionClickEvent(
                    configuration: self.configuration,
                    elementLabel: "Close",
                    elementType: "Modal",
                    actionType: "Close",
                    screenName: "/methods"
                )
            }
        }
    }
    
    private func launchDirectFlowCard(for resolved: ResolvedPaymentMethod) {
        print("type = \(resolved.displayType.rawValue)")
        
        guard resolved.displayType == .card || resolved.displayType == .foreignCard else { return }
        
        let nextVC = PaymentCardViewController(configuration: configuration, useDimming: false)
        
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        
        addChild(nextVC)
        nextVC.view.frame = view.bounds
        nextVC.view.alpha = 0
        view.addSubview(nextVC.view)
        
        UIView.animate(withDuration: 0.35) {
            nextVC.view.alpha = 1
        }
        
        nextVC.didMove(toParent: self)
    }
    
    private func launchDirectFlowOtherMethods(for resolved: ResolvedPaymentMethod) {
        let type = resolved.displayType
        
        guard let controller = presentingViewController else {
            return
        }
        
        dismiss(animated: false) {
            switch type {
            case .tpay:
                ProgressTPayViewController.present(with: self.configuration, from: controller)
            case .sberPay:
                ProgressSberPayViewController.present(with: self.configuration, from: controller)
            case .dolyame:
                ProgressDolyameViewController.present(with: self.configuration, from: controller)
            case .foreignCard:
                ProgressAltForeignCardViewController.present(with: self.configuration, from: controller)
            case .tInstallment:
                PaymentTInstallmentPeriodViewController.present(with: self.configuration, from: controller)
            case .dr:
                ProgressDRViewController.present(with: self.configuration, from: controller)
            default:
                break
            }
        }
    }
    
    private func launchDirectFlowSbp(for method: PaymentMethod) {
        guard let type = PaymentMethodType(rawValue: method.type ?? "") else { return }
        guard type == .sbp else { return }
        
        let presenter = ProgressSbpPresenter(configuration: configuration)
        let nextVC = ProgressSbpViewController(presenter: presenter, useDimming: false)
        presenter.view = nextVC
        
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        
        addChild(nextVC)
        nextVC.view.frame = view.bounds
        nextVC.view.alpha = 0
        view.addSubview(nextVC.view)
        
        UIView.animate(withDuration: 0.35) {
            nextVC.view.alpha = 1
        }
        
        nextVC.didMove(toParent: self)
    }
    
    private func launchTInstallmentFlow() {
        guard let controller = presentingViewController else {
            return
        }

        dismiss(animated: false) { [weak self] in
            guard let self else { return }
            PaymentTInstallmentPeriodViewController.present(with: self.configuration, from: controller)
        }
    }
}

private extension PaymentOptionsViewController {
    
    func loaderView(isOn: Bool, completion: @escaping () -> Void) {
        if isOn {
            loaderView.isHidden = false
            loaderView.startAnimated()
        } else {
            loaderView.endAnimated()
        }
        
        UIView.animate(withDuration: 0.2) {
            self.loaderView.alpha = isOn ? 1 : 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.loaderView.isHidden = !isOn
            completion()
        }
    }
}

extension PaymentOptionsViewController: BottomSheetPaymentOptionsSelectionButtonDelegate {
    
    func didSelect(method resolved: ResolvedPaymentMethod) {
        let method = resolved.displayType
        
        print("Выбран метод: \(method.rawValue)")
        
        if let sheet = children.first(where: { $0 is BottomSheetController }) as? BottomSheetController,
           let content = sheet.children.first(where: { $0 is BottomSheetPaymentOptionsContentViewController }) as? BottomSheetPaymentOptionsContentViewController {
            configuration.paymentData.isAdditionalMethodsExpanded = content.showAdditional
            configuration.paymentData.isSaveCardSelected = content.saveCardSwitch?.isOn
            configuration.paymentData.isReceiptSelected = content.receiptSwitch?.isOn
        }
        
        AnalyticsService.shared.sendActionClickEvent(
            configuration: configuration,
            elementLabel: method.rawValue,
            elementType: "Button",
            actionType: "Click",
            screenName: "/methods"
        )
        
        launchResolvedMethod(resolved)
    }
    
    func patch(email: String?, tokenize: Bool) {
        let patch = PatchBuilder.make { builder in
            if let email = email?.trimmingCharacters(in: .whitespacesAndNewlines),
               !email.isEmpty,
               email.emailIsValid() {
                builder.replace("/receiptEmail", value: email)
                configuration.paymentData.email = email
            } else {
                configuration.paymentData.email = nil
            }
            
            if case .optional = configuration.paymentData.intentSaveCardState {
                builder.replace("/tokenize", value: tokenize)
                configuration.paymentData.savedTokenize = tokenize
            }
        }
        
        guard !patch.isEmpty else {
            print("PATCH не выполняем: изменений нет")
            return
        }
        
        CloudpaymentsApi.intentPatchById(configuration: configuration, patches: patch) { result in
            print("PATCH выполнен. Email: \(String(describing: result?.receiptEmail)), Tokenize: \(tokenize)")
        }
    }
}
