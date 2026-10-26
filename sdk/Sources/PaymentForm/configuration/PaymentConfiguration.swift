//
//  PaymentConfiguration.swift
//  sdk
//
//  Created by Sergey Iskhakov on 08.10.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

public class PaymentConfiguration {
    let publicId: String
    let paymentData: PaymentData
    let paymentDelegate: PaymentDelegateImpl
    let paymentUIDelegate: PaymentUIDelegateImpl
    let emailBehavior: EmailBehaviorType
    let useDualMessagePayment: Bool
    let disableApplePay: Bool
    var paymentMethodSequence: [PaymentMethodType]
    var singlePaymentMode: PaymentMethodType?
    var successRedirectUrl: String?
    var showResultScreenForSinglePaymentMode: Bool
    var failRedirectUrl: String?
   
    public init(publicId: String, paymentData: PaymentData, delegate: PaymentDelegate? = nil, uiDelegate: PaymentUIDelegate? = nil, emailBehavior: EmailBehaviorType = .required, paymentMethodSequence: [PaymentMethodType], singlePaymentMode: PaymentMethodType? = nil, useDualMessagePayment: Bool = false, disableApplePay: Bool = true, showResultScreenForSinglePaymentMode: Bool = true, successRedirectUrl: String? = nil, failRedirectUrl: String? = nil) {
        self.publicId = publicId
        self.paymentData = paymentData
        self.paymentDelegate = PaymentDelegateImpl.init(delegate: delegate)
        self.paymentUIDelegate = PaymentUIDelegateImpl.init(delegate: uiDelegate)
        self.emailBehavior = emailBehavior
        self.useDualMessagePayment = useDualMessagePayment
        self.disableApplePay = disableApplePay
        self.showResultScreenForSinglePaymentMode = showResultScreenForSinglePaymentMode
        self.successRedirectUrl = successRedirectUrl
        self.failRedirectUrl = failRedirectUrl
        self.paymentMethodSequence = paymentMethodSequence
        self.singlePaymentMode = singlePaymentMode
    }
}

public enum EmailBehaviorType {
    case required
    case hidden
    case optional
}

