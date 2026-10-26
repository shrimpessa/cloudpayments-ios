//
//  PaymentDelegate.swift
//  sdk
//
//  Created by Sergey Iskhakov on 08.10.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import Foundation

public enum PaymentResultAction {
    case success
    case error
    case close
}

public protocol PaymentDelegate: AnyObject {
    func onPaymentFinished(_ transactionId: Int64?)
    func onPaymentFailed(_ errorMessage: String?)
    func onPaymentClosed()
}

public protocol PaymentUIDelegate: AnyObject {
    func paymentFormWillDisplay()
    func paymentFormDidDisplay()
    func paymentFormWillHide()
    func paymentFormDidHide()
}

internal class PaymentDelegateImpl {
    weak var delegate: PaymentDelegate?
    
    init(delegate: PaymentDelegate?) {
        self.delegate = delegate
    }
    
    func paymentFinished(_ transaction: PaymentTransactionResponse?){
        self.delegate?.onPaymentFinished(transaction?.transactionId)
    }
    
    func paymentFailed(_ errorMessage: String?) {
        self.delegate?.onPaymentFailed(errorMessage)
    }
    
    func paymentClosed() {
        self.delegate?.onPaymentClosed()
    }
}

internal class PaymentUIDelegateImpl {
    weak var delegate: PaymentUIDelegate?
    
    init(delegate: PaymentUIDelegate?) {
        self.delegate = delegate
    }
    
    func paymentFormWillDisplay() {
        self.delegate?.paymentFormWillDisplay()
    }
    
    func paymentFormDidDisplay() {
        self.delegate?.paymentFormDidDisplay()
    }
    
    func paymentFormWillHide() {
        self.delegate?.paymentFormWillHide()
    }
    
    func paymentFormDidHide() {
        self.delegate?.paymentFormDidHide()
    }
}
