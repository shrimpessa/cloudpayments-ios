//
//  PaymentForm.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import UIKit
import PassKit
import WebKit

typealias PaymentCallbackIntentApi = (_ status: Bool, _ canceled: Bool, _ transaction: PaymentIntentResponse?, _ errorMessage: String?) -> ()

public class PaymentForm: BaseViewController {
    
    // MARK: - Public Properties
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var threeDsCloseButton: Button?
    @IBOutlet private weak var threeDsFormView: UIView?
    @IBOutlet private weak var threeDsContainerView: UIView?
    
    var configuration: PaymentConfiguration!
    
//    lazy var network: CloudpaymentsApi = CloudpaymentsApi.init(publicId: self.configuration.publicId, apiUrl: self.configuration.apiUrl)
    lazy var customTransitionDelegateInstance = FormTransitioningDelegate(viewController: self)
    
    // MARK: - Private Properties
    private lazy var threeDsProcessor: ThreeDsProcessor = ThreeDsProcessor()
    private var threeDsCallbackId: String = ""
    
    private var threeDsCompletionIntentApi: PaymentCallbackIntentApi?
    private var paymentResponse: PaymentIntentResponse?
    
    // MARK: - Internal methods
    
    internal func show(inViewController controller: UIViewController, completion: (() -> ())?) {
        self.transitioningDelegate = customTransitionDelegateInstance
        self.modalPresentationStyle = .custom
        controller.present(self, animated: true, completion: completion)
    }
    
    internal func open(inViewController controller: UIViewController, completion: (() -> ())?) {
        self.transitioningDelegate = customTransitionDelegateInstance
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
        
        controller.present(self, animated: true, completion: completion)
    }
    
    func hide(completion: (()->())?) {
        self.dismiss(animated: true) {
            completion?()
        }
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        configureThreeDsCloseButton()
        
        LoggerService.shared.startLogging(publicId: configuration.publicId)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // MARK: - Close button method on PaymentForm
    @IBAction private func onClose(_ sender: UIButton) {
        self.configuration.paymentUIDelegate.paymentFormWillHide()
        self.hide { [weak self] in
            self?.configuration.paymentUIDelegate.paymentFormDidHide()
        }
    }
    
//    internal func chargeIntentApi(cardCryptogramPacket: String, email: String?, completion: PaymentCallbackIntentApi?) {
//        network.intentApiPay(cardCryptogram: cardCryptogramPacket, with: configuration) { statusCode, result in
//            if let statusCode = statusCode, let result = result {
//                if statusCode == 202 {
//                    self.show3ds(transactionResponse: result, completion: completion, statusCode: statusCode)
//                } else if statusCode == 200 {
//                    print("Non 3DS — статус: \(String(describing: result.transaction?.status))")
//                    completion?(true, false, result, nil)
//                } else {
//                    completion?(false, false, nil, result.transaction?.code)
//                }
//            } else {
//                completion?(false, false, nil, result?.transaction?.code)
//            }
//        }
//    }
    
//    internal func authIntentApi(cardCryptogramPacket: String, email: String?, completion: PaymentCallbackIntentApi?) {
//        network.intentApiPay(cardCryptogram: cardCryptogramPacket, with: configuration) { statusCode, result in
//            if let statusCode = statusCode, let result = result {
//                if statusCode == 202 {
//                    self.show3ds(transactionResponse: result, completion: completion, statusCode: statusCode)
//                } else if statusCode == 200 {
//                    print("Non 3DS — статус: \(String(describing: result.transaction?.status))")
//                    completion?(true, false, result, nil)
//                } else {
//                    completion?(false, false, nil, result.transaction?.code)
//                }
//            } else {
//                completion?(false, false, nil, result?.transaction?.code)
//            }
//        }
//    }
    
    internal func show3ds(transactionResponse: PaymentIntentResponse, completion: PaymentCallbackIntentApi?, statusCode: Int) {
        self.threeDsCompletionIntentApi = nil
        
        if statusCode == 202 {
            print("Status is \(String(describing: transactionResponse.transaction?.status))")
            
            guard let threeDsCallbackId = transactionResponse.threeDsCallbackId else { return }
            self.threeDsCallbackId = threeDsCallbackId
            guard let paReq = transactionResponse.paReq else { return }
            guard let transactionId = transactionResponse.transaction?.transactionId else { return }
            guard let acsUrl = transactionResponse.acsUrl else { return }
            
            let threeDsData = ThreeDsData(transactionId: String(transactionId), paReq: paReq, acsUrl: acsUrl, threeDSCallbackId: threeDsCallbackId)
            threeDsProcessor.make3DSPayment(with: threeDsData, delegate: self)
            self.threeDsCompletionIntentApi = completion
            self.paymentResponse = transactionResponse
        } else {
            completion?(false, false, transactionResponse, transactionResponse.transaction?.paymentMethod)
        }
    }
    
    // MARK: - Private methods closeThreeds and configureThreeDsCloseButton
    private func closeThreeDs(completion: (() -> ())?) {
        if let form = self.threeDsFormView {
            UIView.animate(withDuration: 0.25) {
                form.alpha = 0
            } completion: { [weak self] (status) in
                form.isHidden = true
                if let container = self?.threeDsContainerView {
                    container.subviews.forEach { $0.removeFromSuperview()}
                }
                
                completion?()
            }
        } else {
            completion?()
        }
    }
    
    private func configureThreeDsCloseButton() {
        self.threeDsCloseButton?.onAction = { [weak self] in
            self?.threeDsCompletionIntentApi?(false, true, nil, nil)
            self?.closeThreeDs { [weak self] in
                self?.threeDsCompletionIntentApi?(false, true, nil, nil)
            }
        }
    }
}
// MARK: - Extensions
extension PaymentForm: ThreeDsDelegate {
    public func onAuthorizationCompleted(with md: String, paRes: String) {
//        self.closeThreeDs { [weak self] in
//            guard let self = self else {
//                return
//            }
//            self.post3ds(transactionId: md, paRes: paRes) { [weak self] response in
//                guard let self = self else {
//                    return
//                }
                
//                self.transaction?.reasonCode = Int(response.reasonCode!) ?? 5204
                
//                self.threeDsCompletion?(response.success, false, self.transaction, response.reasonCode!)
//            }
//        }
    }

    public func onAuthorizationFailed(with code: String) {
        self.closeThreeDs { [weak self] in
            guard let self = self else { return }
            self.threeDsCompletionIntentApi?(false, false, paymentResponse, code)
        }
    }
    
    public func willPresentWebView(_ webView: WKWebView) {
        if let container = self.threeDsContainerView {
            container.addSubview(webView)
            webView.bindFrameToSuperviewBounds()
            
            if let form = self.threeDsFormView {
                form.alpha = 0
                form.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    form.alpha = 1
                }
            }
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
class FormTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    weak var formController: PaymentForm!
    
    init(viewController: PaymentForm) {
        self.formController = viewController
        super.init()
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FormPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
