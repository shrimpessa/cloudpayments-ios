//
//  PaymentSourceForm.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import UIKit
import PassKit

final class PaymentOptionsForm: PaymentForm, PKPaymentAuthorizationViewControllerDelegate  {
    
    @IBOutlet private weak var applePayContainer: View!
    @IBOutlet private weak var payWithCardButton: Button!
    @IBOutlet private weak var mainAppleView: View!
    @IBOutlet private weak var mainTPayView: View!
    @IBOutlet private weak var tPayButton: Button!
    @IBOutlet private weak var sbpButton: Button!
    @IBOutlet private weak var sberPayButton: Button!
    @IBOutlet private weak var loaderTPayView: UIView!
    @IBOutlet private weak var loaderSBPView: UIView!
    @IBOutlet private weak var heightConstraint:NSLayoutConstraint!
    @IBOutlet private weak var paymentLabel: UILabel!
    
    private var supportedPaymentNetworks: [PKPaymentNetwork] {
        get {
            var arr: [PKPaymentNetwork] = [.visa, .masterCard, .JCB]
            if #available(iOS 12.0, *) {
                arr.append(.maestro)
            }
            if #available(iOS 14.5, *) {
                arr.append(.mir)
            }
            
            return arr
        }
    }
    
    private var isOnKeyboard: Bool = false
    private var isCloused = false
    private let loaderView = LoaderView()
    private var constraint: NSLayoutConstraint!
    private var rotation: Double = 0
    private var applePaymentSucceeded: Bool?
    private var resultTransaction: Transaction?
    private var errorMessage: String?
    
    private lazy var progressTPayView: CircleProgressView = .init(frame: .init(x: 0, y: 0, width: 28, height: 28), width: 2)
    private lazy var progressSBPView: CircleProgressView  = .init(frame: .init(x: 0, y: 0, width: 28, height: 28), width: 2)
    private lazy var currentContainerHeight: CGFloat = containerView.bounds.height
    private var heightPresentView: CGFloat { return containerView.bounds.height }
    
    var onCardOptionSelected: ((_  isSaveCard: Bool?) -> ())?
    
    @discardableResult
    public class func present(with configuration: PaymentConfiguration, from: UIViewController, completion: (() -> ())?) -> PaymentForm {
        let storyboard = UIStoryboard.init(name: "PaymentForm", bundle: Bundle.mainSdk)
        
        let controller = storyboard.instantiateViewController(withIdentifier: "PaymentOptionsForm") as! PaymentOptionsForm
        
        controller.configuration = configuration
        controller.open(inViewController: from, completion: completion)
        
        return controller
    }
    
    override func loadView() {
        super.loadView()
        view.addSubview(loaderView)
        loaderView.frame = view.bounds
        loaderView.fullConstraint()
        loaderView.isHidden = true
    }
    
    // MARK: - Lifecycle app
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureApplePayContainers()
        self.hideKeyboardWhenTappedAround()
//        createIntentMethod(configuration: configuration)
        paymentLabel.textColor = .mainText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
        
    private func configureApplePayContainers() {
        
        if configuration.disableApplePay || !configuration.paymentData.splits.isNilOrEmpty {
            mainAppleView.isHidden = true
            applePayContainer.isHidden = true
        } else {
            mainAppleView.isHidden = false
            applePayContainer.isHidden = false
            initializeApplePay()
        }
    }
    
  
    //MARK: - Keyboard
    
    @objc override func onKeyboardWillShow(_ notification: Notification) {
        super.onKeyboardWillShow(notification)
        isOnKeyboard = true
        self.heightConstraint.constant = self.keyboardFrame.height
//        UIView.animate(withDuration: 0.35, delay: 0) {
//            self.view.layoutIfNeeded()
//        }
    }
    
    @objc override func onKeyboardWillHide(_ notification: Notification) {
        super.onKeyboardWillHide(notification)
        isOnKeyboard = false
        self.heightConstraint.constant = 0
        self.currentContainerHeight = 0
        UIView.animate(withDuration: 0.35, delay: 0) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func onApplePay(_ sender: UIButton) {
        errorMessage = nil
        resultTransaction = nil
        applePaymentSucceeded = false
        
        let paymentData = self.configuration.paymentData
        if let applePayMerchantId = paymentData.applePayMerchantId {
            let amount = Double(paymentData.amount) ?? 0.0
            
            let request = PKPaymentRequest()
            request.merchantIdentifier = applePayMerchantId
            request.supportedNetworks = self.supportedPaymentNetworks
            request.merchantCapabilities = PKMerchantCapability.capability3DS
            request.countryCode = "RU"
            request.currencyCode = paymentData.currency
            
            let paymentSummaryItems = [PKPaymentSummaryItem(label: self.configuration.paymentData.description ?? "К оплате", amount: NSDecimalNumber.init(value: amount))]
            request.paymentSummaryItems = paymentSummaryItems
            
            if let applePayController = PKPaymentAuthorizationViewController(paymentRequest:
                                                                                request) {
                applePayController.delegate = self
                applePayController.modalPresentationStyle = .formSheet
                self.present(applePayController, animated: true, completion: nil)
            }
        }
    }
    
    @objc private func onSetupApplePay(_ sender: UIButton) {
        PKPassLibrary().openPaymentSetup()
    }
    
    @IBAction private func onCard(_ sender: UIButton) {
//        openCardForm()
    }
    
//    private func openCardForm() {
//            self.dismiss(animated: false) {
//                self.onCardOptionSelected?(isSave)
//            }
//    }
    
    //MARK: - PKPaymentAuthorizationViewControllerDelegate -
    
    private func initializeApplePay() {
        
        if let _  = configuration.paymentData.applePayMerchantId, PKPaymentAuthorizationViewController.canMakePayments() {
            let button: PKPaymentButton!
            if PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedPaymentNetworks) {
                button = PKPaymentButton.init(paymentButtonType: .plain, paymentButtonStyle: .black)
                button.addTarget(self, action: #selector(onApplePay(_:)), for: .touchUpInside)
            } else {
                button = PKPaymentButton.init(paymentButtonType: .setUp, paymentButtonStyle: .black)
                button.addTarget(self, action: #selector(onSetupApplePay(_:)), for: .touchUpInside)
            }
            button.translatesAutoresizingMaskIntoConstraints = false
            
            if #available(iOS 12.0, *) {
                button.cornerRadius = 8
            } else {
                button.layer.cornerRadius = 8
                button.layer.masksToBounds = true
            }
            
            applePayContainer.isHidden = false
            applePayContainer.addSubview(button)
            button.bindFrameToSuperviewBounds()
        } else {
            applePayContainer.isHidden = true
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        //                controller.dismiss(animated: true) { [weak self] in
        //                    guard let self = self else {
        //                        return
        //                    }
        //                    if let status = self.applePaymentSucceeded {
        //                        let state: PaymentProcessForm.State
        //
        //                        if status {
        //                            state = .succeeded(self.resultTransaction)
        //                        } else {
        //                            state = .failed(self.errorMessage)
        //                        }
        //
        //                        let parent = self.presentingViewController
        //                        self.dismiss(animated: true) { [weak self] in
        //                            guard let self = self else {
        //                                return
        //                            }
        //                            if parent != nil {
        //                                PaymentProcessForm.present(with: self.configuration, cryptogram: nil, email: nil, state: state, from: parent!, completion: nil)
        //                            }
        //                        }
        //                    }
        //                }
    }
    
    //    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
    //
    //        if let cryptogram = payment.convertToString() {
    //            if (configuration.useDualMessagePayment) {
    //                self.auth(cardCryptogramPacket: cryptogram, email: nil) { [weak self] status, canceled, transaction, errorMessage in
    //                    guard let self = self else {
    //                        return
    //                    }
    //                    self.applePaymentSucceeded = status
    //                    self.resultTransaction = transaction
    //                    self.errorMessage = errorMessage
    //
    //                    if status {
    //                        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    //                    } else {
    //                        var errors = [Error]()
    //                        if let message = errorMessage {
    //                            let userInfo = [NSLocalizedDescriptionKey: message]
    //                            let error = PKPaymentError(.unknownError, userInfo: userInfo)
    //                            errors.append(error)
    //                        }
    //                        completion(PKPaymentAuthorizationResult(status: .failure, errors: errors))
    //                    }
    //                }
    //            } else {
    //                self.charge(cardCryptogramPacket: cryptogram, email: nil) { [weak self] status, canceled, transaction, errorMessage in
    //                    guard let self = self else {
    //                        return
    //                    }
    //                    self.applePaymentSucceeded = status
    //                    self.resultTransaction = transaction
    //                    self.errorMessage = errorMessage
    //
    //                    if status {
    //                        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    //                    } else {
    //                        var errors = [Error]()
    //                        if let message = errorMessage {
    //                            let userInfo = [NSLocalizedDescriptionKey: message]
    //                            let error = PKPaymentError(.unknownError, userInfo: userInfo)
    //                            errors.append(error)
    //                        }
    //                        completion(PKPaymentAuthorizationResult(status: .failure, errors: errors))
    //                    }
    //                }
    //            }
    //        } else {
    //            completion(PKPaymentAuthorizationResult(status: PKPaymentAuthorizationStatus.failure, errors: []))
    //        }
    //    }
}
