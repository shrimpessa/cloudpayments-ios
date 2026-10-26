//
//  ProgressSberPayPresenter.swift
//  sdk
//
//  Created by Cloudpayments on 20.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

protocol ProgressSberPayViewControllerProtocol: AnyObject {
    func resultPayment(result: PaymentResultAction, error: String?, transaction: PaymentTransactionResponse?)
    func openLinkUrls(urls: [URL])
    func showAlert(message: String?, title: String?)
}

final class ProgressSberPayPresenter {
    let configuration: PaymentConfiguration
    private let sberPayPollingService: PaymentPollingService
    private var currentPuid: String?
    weak var view: ProgressSberPayViewControllerProtocol?

    // MARK: - Init
    init(configuration: PaymentConfiguration,
         sberPayPollingService: PaymentPollingService = PaymentPollingServiceImpl()) {
        self.configuration = configuration
        self.sberPayPollingService = sberPayPollingService
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(intentSberPayObserverStatus(_:)),
            name: ObserverKeys.intentSberPayObserver.key,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopPolling()
    }

    // MARK: - Polling
    func stopPolling() {
        sberPayPollingService.stopPolling()
    }

    private func pollStatus() {
        CloudpaymentsApi.getIntentWaitStatus(configuration, type: .sberPay) { [weak self] statusCode in
            guard let self = self else { return }
            if statusCode == 200 {
                print("pollStatus: 200 — продолжаем опрос")
            } else {
                self.stopPolling()
                self.view?.showAlert(message: .errorWordTitle, title: nil)
            }
        }
    }

    private func startPolling() {
        stopPolling()
        sberPayPollingService.startPolling(taskName: .sberPayTransactionPolling, interval: 3) { [weak self] in
            self?.pollStatus()
        }
    }

    // MARK: - Intent Status Handling
    @objc private func intentSberPayObserverStatus(_ notification: NSNotification) {
        guard let statusModel = notification.object as? PaymentTransactionStatusModel,
              let intentStatusRaw = statusModel.status,
              let intentStatus = IntentWaitStatus(rawValue: intentStatusRaw),
              let puid = currentPuid,
              let transactions = statusModel.transactions else {
            return
        }

        let matchedTransactions = transactions.filter { $0.puid == puid }
        guard !matchedTransactions.isEmpty else { return }

        for transaction in matchedTransactions {
            guard let transactionStatusRaw = transaction.status,
                  let intentTransactionStatus = IntentTransactionStatus(rawValue: transactionStatusRaw) else { continue }

            handleIntentTransactionFinalStatus(intentTransactionStatus, transaction: transaction)
        }

        if intentStatus == .succeeded {
            stopPolling()
        }
    }

    // MARK: - Transaction Status Handling
    private func handleIntentTransactionFinalStatus(_ status: IntentTransactionStatus,
                                                    transaction: PaymentTransactionResponse) {
        stopPolling()
        
        let transactionId = transaction.transactionId
        let transactionErrorCode = transaction.code
        
        switch status {
        case .authorized, .completed:
            print("Оплата успешна — \(status.rawValue)")
            print("Номер транзакции \(String(describing: transactionId))")
            let paymentIntentTransaction = PaymentTransactionResponse(
                transactionId: transactionId,
                paymentMethod: nil,
                puid: currentPuid,
                status: status.rawValue,
                code: nil
            )
            view?.resultPayment(result: .success, error: nil, transaction: paymentIntentTransaction)
            
        case .declined, .cancelled:
            print("Оплата отклонена — code: \(String(describing: transactionErrorCode))")
            print("Номер транзакции \(String(describing: transactionId))")
            let errorMessage = ApiError.getFullErrorDescriptionIntentApi(from: transactionErrorCode)
            let paymentIntentTransaction = PaymentTransactionResponse(
                transactionId: transactionId,
                paymentMethod: nil,
                puid: currentPuid,
                status: status.rawValue,
                code: transactionErrorCode
            )
            view?.resultPayment(result: .error, error: errorMessage, transaction: paymentIntentTransaction)
        }
    }

    // MARK: - Input
    func getSberPayLinkIntentApi() {
        let puid = UUID().uuidString
        currentPuid = puid

        CloudpaymentsApi.getSberPayLinkIntentApi(puid: puid, configuration: configuration) { [weak self] statusCode, sberPayLink in
            guard let self = self else { return }
            switch statusCode {
            case 200:
                guard let links = sberPayLink?.redirectUrls, !links.isEmpty else {
                    self.view?.showAlert(message: .banksAppNotOpen, title: nil)
                    return
                }
                let validUrls = links.compactMap { URL(string: $0) }
                self.view?.openLinkUrls(urls: validUrls)
                self.startPolling()
            case 409:
                self.view?.resultPayment(result: .success, error: .orderAlreadyBeenPaid, transaction: nil)
            default:
                self.view?.showAlert(message: .errorWordTitle, title: nil)
            }
        }
    }
}
