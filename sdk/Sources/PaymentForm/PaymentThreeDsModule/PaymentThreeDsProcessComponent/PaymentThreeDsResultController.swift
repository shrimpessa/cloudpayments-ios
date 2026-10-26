//
//  PaymentThreeDsResultController.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit

final class PaymentThreeDsResultController: BaseViewController {
    
    private var cryptogram: String?
    private var email: String?
    private let configuration: PaymentConfiguration
    private let progressView = ProgressPaymentView(method: .card)
    private lazy var payment3DsProcessController: PaymentThreeDsProcessController = {
        return PaymentThreeDsProcessController(configuration: configuration)
    }()
    
    // MARK: - Init
    init(configuration: PaymentConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func present(with configuration: PaymentConfiguration,
                       cryptogram: String?,
                       email: String?,
                       from controller: UIViewController) {
        let vc = PaymentThreeDsResultController(configuration: configuration)
        vc.cryptogram = cryptogram
        vc.email = email
        controller.present(vc, animated: true)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        addProgressView()
        add3dsController()
        handle3dsResult()
    }
    
    private func handle3dsResult() {
        guard let cryptogram = self.cryptogram else { return }
        
        payment3DsProcessController.cardPay(
            cardCryptogramPacket: cryptogram,
            email: self.email
        ) { [weak self] status, canceled, transaction, code in
            guard let self = self else { return }
            
            if status {
                if code == .orderAlreadyBeenPaid {
                    self.resultPayment(
                        result: .success,
                        error: .orderAlreadyBeenPaid,
                        transaction: transaction?.transaction
                    )
                } else {
                    self.resultPayment(
                        result: .success,
                        error: nil,
                        transaction: transaction?.transaction
                    )
                }
            }  else if canceled {
                self.configuration.paymentUIDelegate.paymentFormWillHide()
                self.dismiss(animated: true) { [weak self] in
                    self?.configuration.paymentUIDelegate.paymentFormDidHide()
                }
            } else {
                let apiError = code.flatMap {
                    ApiError.getFullErrorDescriptionIntentApi(from: $0)
                }
                
                var failedTransaction = transaction?.transaction
    
                if failedTransaction?.code == nil {
                    failedTransaction = PaymentTransactionResponse(
                        transactionId: transaction?.transaction?.transactionId,
                        paymentMethod: transaction?.transaction?.paymentMethod,
                        puid: nil,
                        status: transaction?.transaction?.status,
                        code: code
                    )
                }
                
                self.resultPayment(
                    result: .error,
                    error: apiError,
                    transaction: failedTransaction
                )
            }
        }
    }
    
    private func addProgressView() {
        view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func add3dsController() {
        addChild(payment3DsProcessController)
        view.addSubview(payment3DsProcessController.view)
        payment3DsProcessController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            payment3DsProcessController.view.topAnchor.constraint(equalTo: view.topAnchor),
            payment3DsProcessController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            payment3DsProcessController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            payment3DsProcessController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        payment3DsProcessController.didMove(toParent: self)
    }
}

// MARK: - Result handling
private extension PaymentThreeDsResultController {
    
    func resultPayment(
        result: PaymentResultAction,
        error: String?,
        transaction: PaymentTransactionResponse?
    ) {
        let configuration = self.configuration
        guard let parent = presentingViewController else { return }
        
        if configuration.singlePaymentMode != nil {
            if configuration.showResultScreenForSinglePaymentMode {
                handleSingleMethodResultScreen(
                    result: result,
                    error: error,
                    transaction: transaction,
                    configuration: configuration,
                    parent: parent
                )
            } else {
                handleSingleMethodNoResultScreen(
                    result: result,
                    error: error,
                    transaction: transaction,
                    configuration: configuration
                )
            }
        } else {
            handleStandartMethodResultScreen(
                result: result,
                error: error,
                transaction: transaction,
                configuration: configuration,
                parent: parent
            )
        }
    }
    
    func handleSingleMethodResultScreen(
        result: PaymentResultAction,
        error: String?,
        transaction: PaymentTransactionResponse?,
        configuration: PaymentConfiguration,
        parent: UIViewController
    ) {
        dismiss(animated: false) {
            switch result {
            case .success:
                let amountText = "\(configuration.paymentData.amount) \(Currency.getCurrencySign(code: configuration.paymentData.currency))"
                PaymentResultViewController.present(
                    from: parent,
                    state: .completed(amountText: amountText, transaction: transaction), orderAlreadyBeenPaid: error) {
                    configuration.paymentDelegate.paymentFinished(transaction)
                    configuration.paymentDelegate.paymentClosed()
                    AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "ReturnToShop", elementType: "Button", actionType: "Click", screenName: "/success")
                }
                AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/success", methodChosen: "Card", cardFieldsCount: 0, eventType: "Open")
            case .error:
                PaymentResultViewController.present(from: parent, state: .declined(message: error)) {
                    configuration.paymentDelegate.paymentFailed(error)
                    AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "Try again", elementType: "Button", actionType: "Click", screenName: "/fail")
                }
                AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/fail", methodChosen: "Card", cardFieldsCount: 0, eventType: "Open", errorContext: transaction?.code)
            case .close:
                configuration.paymentDelegate.paymentClosed()
            }
        }
    }
    
    func handleSingleMethodNoResultScreen(
        result: PaymentResultAction,
        error: String?,
        transaction: PaymentTransactionResponse?,
        configuration: PaymentConfiguration
    ) {
        dismiss(animated: true) {
            switch result {
            case .success:
                configuration.paymentDelegate.paymentFinished(transaction)
            case .error:
                configuration.paymentDelegate.paymentFailed(error)
            case .close:
                configuration.paymentDelegate.paymentClosed()
            }
        }
    }
    
    func handleStandartMethodResultScreen(
        result: PaymentResultAction,
        error: String?,
        transaction: PaymentTransactionResponse?,
        configuration: PaymentConfiguration,
        parent: UIViewController
    ) {
        dismiss(animated: false) {
            switch result {
            case .success:
                let amountText = "\(configuration.paymentData.amount) \(Currency.getCurrencySign(code: configuration.paymentData.currency))"
                PaymentResultViewController.present(from: parent, state: .completed(amountText: amountText, transaction: transaction), orderAlreadyBeenPaid: error) {
                    configuration.paymentDelegate.paymentFinished(transaction)
                    configuration.paymentDelegate.paymentClosed()
                    AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "ReturnToShop", elementType: "Button", actionType: "Click", screenName: "/success")
                }
                AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/success", methodChosen: "Card", cardFieldsCount: 0, eventType: "Open")
            case .error:
                PaymentResultViewController.present(from: parent, state: .declined(message: error)) {
                    configuration.paymentDelegate.paymentFailed(error)
                    PaymentOptionsViewController.present(with: configuration, from: parent, skipLoader: true)
                    AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "Try again", elementType: "Button", actionType: "Click", screenName: "/fail")
                    AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: configuration)
                }
                AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/fail", methodChosen: "Card", cardFieldsCount: 0, eventType: "Open", errorContext: transaction?.code)
            case .close:
                configuration.paymentDelegate.paymentClosed()
                PaymentOptionsViewController.present(with: configuration, from: parent, skipLoader: true)
                AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "ChooseOtherMethod", elementType: "Button", actionType: "Click", screenName: "/methods")
                AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: configuration)
            }
        }
    }
}
