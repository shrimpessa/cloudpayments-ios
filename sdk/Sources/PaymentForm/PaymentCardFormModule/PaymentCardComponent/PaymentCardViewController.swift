//
//  PaymentCardViewController.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit

final class PaymentCardViewController: BaseViewController {
    
    private let configuration: PaymentConfiguration
    private let useDimming: Bool
    
    init(configuration: PaymentConfiguration, useDimming: Bool = true) {
        self.configuration = configuration
        self.useDimming = useDimming
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = useDimming ? UIColor.black.withAlphaComponent(0.5) : .clear
    }
    @MainActor required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    class func present(with configuration: PaymentConfiguration, from presentingViewController: UIViewController) {
        let controller = PaymentCardViewController(configuration: configuration)
        presentingViewController.present(controller, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showCardContent()
        LoggerService.shared.startLogging(publicId: configuration.publicId)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configuration.paymentUIDelegate.paymentFormWillDisplay()
        configuration.paymentUIDelegate.paymentFormDidDisplay()
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/methods/card-edit", methodChosen: "Card", cardFieldsCount: 3, eventType: "Open")
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/methods/card-edit", cardFieldsCount: 3, eventType: "CardInputShown")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        configuration.paymentUIDelegate.paymentFormWillHide()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        configuration.paymentUIDelegate.paymentFormDidHide()
    }
    
    private func showCardContent() {
        let amountText = "\(configuration.paymentData.amount) \(Currency.getCurrencySign(code: configuration.paymentData.currency))"
        let contentVC = PaymentCardContentViewController(amountText: amountText)
        
        contentVC.onCardNumberCompleted = { [weak self] in
            guard let self else { return }
            AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "CardNumber", elementType: "Input", actionType: "Fill", screenName: "/methods/card-edit", methodChosen: "Card")
        }
        
        contentVC.onCardDataFillStarted = { [weak self] in
            guard let self else { return }

            AnalyticsService.shared.sendActionClickEvent(configuration: self.configuration, elementLabel: "CardDataFillStarted", elementType: "Input", actionType: "Fill", screenName: "/methods/card-edit", methodChosen: "Card")
        }
        
        contentVC.requestBinInfo = { [weak self] cleanCard, completion in
            guard let self = self else { return }
            CloudpaymentsApi.getBinInfoWithIntentId(cleanCardNumber: cleanCard, with: self.configuration) { model, success in
                guard success == true else { completion(nil); return }
                let info = BinInfoLight(
                    hideCvvInput: model?.hideCvvInput ?? false,
                    convertedAmount: model?.convertedAmount,
                    currencyCode: model?.currency
                )
                completion(info)
            }
        }
        
        contentVC.onCardTypeDefined = { [weak self] type in
            guard let self else { return }

            AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/methods/card-edit", methodChosen: "Card", cardFieldsCount: 3, eventType: "CardTypeDefinition")
        }
        
        contentVC.onExpiredDateFilled = { [weak self] in
            guard let self else { return }

            AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "ExpiredDate", elementType: "Input", actionType: "Fill", screenName: "/methods/card-edit", methodChosen: "Card")
        }

        contentVC.onCvvFilled = { [weak self] in
            guard let self else { return }

            AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "CVV", elementType: "Input", actionType: "Fill", screenName: "/methods/card-edit", methodChosen: "Card")
        }
        
        contentVC.onCardDataFillFinished = { [weak self] in
            guard let self else { return }
            
            AnalyticsService.shared.sendActionClickEvent(configuration: self.configuration, elementLabel: "CardDataFillFinished", elementType: "Input", actionType: "Fill", screenName: "/methods/card-edit", methodChosen: "Card")
        }
        
        contentVC.onPayTapped = { [weak self] card, exp, cvv in
            
            guard let self else { return }
            guard let pem = configuration.paymentData.pem,
                  let version = configuration.paymentData.version else { return }
            
            let cleanExp = exp.replacingOccurrences(of: " ", with: "")
            
            guard let cryptogram = Card.makeCardCryptogramPacket(
                cardNumber: card,
                expDate: cleanExp,
                cvv: cvv,
                merchantPublicID: configuration.publicId,
                publicKey: pem,
                keyVersion: version
            ) else {
                self.showAlert(title: .errorWord, message: .errorCreatingCryptoPacket)
                return
            }
            
            AnalyticsService.shared.sendActionClickEvent(configuration: configuration, elementLabel: "PayByCard", elementType: "Button", actionType: "Click", screenName: "/methods/card-edit", methodChosen: "Card", actionContext: "Valid")
            
            let parent = self.presentingViewController
            self.dismiss(animated: true) {
                guard let parent = parent ?? UIApplication.topViewController() else { return }
                PaymentThreeDsResultController.present(
                    with: self.configuration,
                    cryptogram: cryptogram,
                    email: self.configuration.paymentData.email,
                    from: parent
                )
            }
        }
        
        let vm = BottomSheetViewModel(cornerRadius: 20)
        let sheet = BottomSheetController(viewModel: vm, content: contentVC)
        
        sheet.onDismiss = { [weak self] isSwipe in
            guard let self else { return }
            if isSwipe {
                if configuration.singlePaymentMode != nil {
                    self.dismiss(animated: true) { [configuration] in
                        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/methods/card-edit", methodChosen: "Сard", cardFieldsCount: 3, eventType: "Close")
                        AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: configuration)
                    }
                } else {
                    self.dismiss(animated: true) { [configuration] in
                        if let top = UIApplication.topViewController() {
                            PaymentOptionsViewController.present(
                                with: configuration,
                                from: top,
                                skipLoader: true
                            )
                            AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/methods/card-edit", methodChosen: "Сard", cardFieldsCount: 3, eventType: "Close")
                            AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(configuration: configuration)
                        }
                    }
                }
            } else {
                self.dismiss(animated: true)
            }
        }
        sheet.present(in: self)
    }
}

extension PaymentCardViewController: PaymentResultViewControllerDelegate {
    func paymentResultPrimaryTapped(state: PaymentResultViewController.State) {
        switch state {
        case .declined:
            if configuration.singlePaymentMode != nil {
                self.dismiss(animated: true)
            } else {
                guard let parent = self.presentedViewController else { return }
                self.dismiss(animated: true) {
                    PaymentOptionsViewController.present(with: self.configuration, from: parent, skipLoader: true)
                }
            }
        case .completed:
            self.dismiss(animated: true)
            break
        }
    }
}
