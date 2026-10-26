//
//  PaymentThreeDsProcessController.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import WebKit
import PassKit

final class PaymentThreeDsProcessController: BaseViewController {

    typealias PaymentCallbackIntentApi = (_ status: Bool, _ canceled: Bool, _ transaction: PaymentIntentResponse?, _ errorMessage: String?) -> ()

    // MARK: UI
    private let threeDsFormView = UIView()
    private let threeDsContainerView = UIView()
    private let threeDsCloseButton = CPButton()

    // MARK: 3DS engine & networking
    private lazy var threeDsProcessor = IntentThreeDsProcessor()
    private var threeDsCallbackId: String = ""
    private var threeDsCompletionIntentApi: PaymentCallbackIntentApi?
    private var paymentResponse: PaymentIntentResponse?

    lazy var network: CloudpaymentsApi = CloudpaymentsApi(publicId: configuration.publicId,
                                                          apiUrl: CloudpaymentsApi.baseURLString)

    // MARK: Config
    private let configuration: PaymentConfiguration

    // MARK: Init
    init(configuration: PaymentConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: .mainSdk)
    }
    
    @MainActor required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupThreeDsUI()
        configureThreeDsCloseButton()
    }
}

// MARK: - UI setup

private extension PaymentThreeDsProcessController {
    func setupThreeDsUI() {
        view.backgroundColor = .clear

        threeDsFormView.translatesAutoresizingMaskIntoConstraints = false
        threeDsFormView.backgroundColor = .white
        threeDsFormView.isHidden = true
        threeDsFormView.alpha = 0
        view.addSubview(threeDsFormView)

        threeDsCloseButton.translatesAutoresizingMaskIntoConstraints = false
                threeDsCloseButton.setIcon(UIImage(systemName: "xmark"))
                threeDsCloseButton.setPadding(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
        threeDsFormView.addSubview(threeDsCloseButton)

        threeDsContainerView.translatesAutoresizingMaskIntoConstraints = false
        threeDsContainerView.backgroundColor = .clear
        threeDsFormView.addSubview(threeDsContainerView)

        NSLayoutConstraint.activate([
            threeDsFormView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            threeDsFormView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            threeDsFormView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            threeDsFormView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            threeDsCloseButton.topAnchor.constraint(equalTo: threeDsFormView.topAnchor, constant: 8),
            threeDsCloseButton.trailingAnchor.constraint(equalTo: threeDsFormView.trailingAnchor, constant: -8),
            threeDsCloseButton.widthAnchor.constraint(equalToConstant: 36),
            threeDsCloseButton.heightAnchor.constraint(equalToConstant: 36),

            threeDsContainerView.topAnchor.constraint(equalTo: threeDsCloseButton.bottomAnchor, constant: 4),
            threeDsContainerView.leadingAnchor.constraint(equalTo: threeDsFormView.leadingAnchor),
            threeDsContainerView.trailingAnchor.constraint(equalTo: threeDsFormView.trailingAnchor),
            threeDsContainerView.bottomAnchor.constraint(equalTo: threeDsFormView.bottomAnchor)
        ])
    }

    func configureThreeDsCloseButton() {
        threeDsCloseButton.onAction = { [weak self] in
            guard let self else { return }
            self.threeDsCompletionIntentApi?(false, true, nil, nil)
            self.closeThreeDs { [weak self] in
                self?.threeDsCompletionIntentApi?(false, true, nil, nil)
            }
        }
    }

    func showThreeDsForm(animated: Bool = true) {
        threeDsFormView.isHidden = false
        guard animated else { threeDsFormView.alpha = 1; return }
        UIView.animate(withDuration: 0.25) { self.threeDsFormView.alpha = 1 }
    }

    func closeThreeDs(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.threeDsFormView.alpha = 0
        }, completion: { _ in
            self.threeDsFormView.isHidden = true
            self.threeDsContainerView.subviews.forEach { $0.removeFromSuperview() }
            completion?()
        })
    }
}

// MARK: - Intent API

extension PaymentThreeDsProcessController {
        
    func cardPay(cardCryptogramPacket: String, email: String?, completion: PaymentCallbackIntentApi?) {
        network.intentApiPay(cardCryptogram: cardCryptogramPacket, with: configuration) { statusCode, result in
            guard let status = statusCode, let result = result else {
                completion?(false, false, nil, result?.transaction?.code)
                return
            }
            switch status {
            case 200:
                completion?(true, false, result, nil)
            case 202:
                self.show3ds(transactionResponse: result, completion: completion, statusCode: status)
            case 409:
                completion?(true, false, result, .orderAlreadyBeenPaid)
            default:
                completion?(false, false, nil, result.transaction?.code)
            }
        }
    }

    func show3ds(transactionResponse: PaymentIntentResponse, completion: PaymentCallbackIntentApi?, statusCode: Int) {
        self.threeDsCompletionIntentApi = nil

        if statusCode == 202 {
            guard
                let callbackId = transactionResponse.threeDsCallbackId,
                let paReq = transactionResponse.paReq,
                let transactionId = transactionResponse.transaction?.transactionId,
                let acsUrl = transactionResponse.acsUrl,
                let intentId = configuration.paymentData.intentId
            else {
                completion?(false, false, transactionResponse, "3DS data missing")
                return
            }

            self.threeDsCallbackId = callbackId

            let threeDsData = ThreeDsData(
                transactionId: String(transactionId),
                paReq: paReq,
                acsUrl: acsUrl,
                threeDSCallbackId: callbackId
            )

            threeDsProcessor.make3DSPaymentByIntent(with: threeDsData, delegate: self, with: intentId)
            self.threeDsCompletionIntentApi = completion
            self.paymentResponse = transactionResponse
        } else {
            completion?(false, false, transactionResponse, transactionResponse.transaction?.paymentMethod)
        }
    }
}

// MARK: - ThreeDsDelegate

extension PaymentThreeDsProcessController: IntentThreeDsDelegate {
    public func willPresentWebView(_ webView: WKWebView) {
        threeDsContainerView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: threeDsContainerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: threeDsContainerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: threeDsContainerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: threeDsContainerView.bottomAnchor)
        ])
        showThreeDsForm(animated: true)
        AnalyticsService.shared.sendScreenOpenedEvent(configuration: configuration, screenName: "/3ds", methodChosen: "Card", cardFieldsCount: 0, eventType: "Open")
    }

    public func onAuthorizationCompleted(with transactionStatus: Bool?) {
        closeThreeDs { [weak self] in
            guard let self, let status = transactionStatus else { return }
            self.threeDsCompletionIntentApi?(status, false, self.paymentResponse, nil)
        }
    }

    public func onAuthorizationFailed(with code: String) {
        closeThreeDs { [weak self] in
            guard let self else { return }
            self.threeDsCompletionIntentApi?(false, false, self.paymentResponse, code)
        }
    }
}
