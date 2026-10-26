//
//  ProgressDRViewController.swift
//  sdk
//
//  Created by Cloudpayments on 30.09.2026.
//  Copyright © 2026 Cloudpayments. All rights reserved.
//

import UIKit

final class ProgressDRViewController: UIViewController {
    
    private let customView = ProgressPaymentView(method: .dr)
    private let presenter: ProgressDRPresenter
    
    // MARK: - Init
    init(presenter: ProgressDRPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.isOpaque = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    class func present(with configuration: PaymentConfiguration, from: UIViewController) {
        let presenter = ProgressDRPresenter(configuration: configuration)
        let controller = ProgressDRViewController(presenter: presenter)
        presenter.view = controller
        from.present(controller, animated: false)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - LifeCycle
    override func loadView() {
        super.loadView()
        view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customView.delegate = self
        presenter.getDRLinkIntentApi()
        LoggerService.shared.startLogging(publicId: presenter.configuration.publicId)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: presenter.configuration, screenName: "Waiting", methodChosen: "DR", cardFieldsCount: 0, eventType: "Open")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter.stopPolling()
    }
}

// MARK: - ProgressPaymentViewDelegate
extension ProgressDRViewController: ProgressPaymentViewDelegate {
    func closePaymentButton() {
        resultPayment(result: .close, error: nil, transaction: nil)
    }
}

// MARK: - ProgressTPayViewControllerProtocol
extension ProgressDRViewController: ProgressDRViewControllerProtocol {
    
    func showAlert(message: String?, title: String?) {
        showAlert(title: title, message: message)
    }
    
    func openLinkURL(url: URL) {
        UIApplication.shared.open(url) { success in
            if !success {
                self.showAlert(title: nil, message: .banksAppNotOpen) { [weak self] in
                    guard let self, let parent = self.presentingViewController else { return }
                    self.dismiss(animated: false) {
                        PaymentOptionsViewController.present(
                            with: self.presenter.configuration,
                            from: parent,
                            skipLoader: true
                        )
                        AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: self.presenter.configuration)
                    }
                }
            }
        }
    }
    
    func resultPayment(
        result: PaymentResultAction,
        error: String?,
        transaction: PaymentTransactionResponse?
    ) {
        let configuration = presenter.configuration
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
}

// MARK: - Result handling
private extension ProgressDRViewController {
    
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
                AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/success", methodChosen: "DR", cardFieldsCount: 0, eventType: "Open")
            case .error:
                PaymentResultViewController.present(from: parent, state: .declined(message: error)) {
                    configuration.paymentDelegate.paymentFailed(error)
                    AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "Try again", elementType: "Button", actionType: "Click", screenName: "/fail")
                }
                AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/fail", methodChosen: "DR", cardFieldsCount: 0, eventType: "Open", errorContext: transaction?.code)
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
                    configuration.paymentDelegate.paymentClosed()
                    configuration.paymentDelegate.paymentFinished(transaction)
                    AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "ReturnToShop", elementType: "Button", actionType: "Click", screenName: "/success")
                }
                AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/success", methodChosen: "DR", cardFieldsCount: 0, eventType: "Open")
            case .error:
                PaymentResultViewController.present(from: parent,state: .declined(message: error)) {
                    configuration.paymentDelegate.paymentFailed(error)
                    PaymentOptionsViewController.present(with: configuration, from: parent, skipLoader: true)
                    AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "Try again", elementType: "Button", actionType: "Click", screenName: "/fail")
                    AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: configuration)
                }
                AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/fail", methodChosen: "DR", cardFieldsCount: 0, eventType: "Open", errorContext: transaction?.code)
            case .close:
                configuration.paymentDelegate.paymentClosed()
                PaymentOptionsViewController.present(with: configuration, from: parent, skipLoader: true)
                AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "ChooseOtherMethod", elementType: "Button", actionType: "Click", screenName: "/methods")
                AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: configuration)
            }
        }
    }
}

