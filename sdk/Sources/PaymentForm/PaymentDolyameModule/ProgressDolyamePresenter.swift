//
//  ProgressDolyamePresenter.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import Foundation

protocol ProgressDolyameViewControllerProtocol: AnyObject {
    func resultPayment(result: PaymentResultAction, error: String?, transaction: PaymentTransactionResponse?)
    func openLinkURL(url: URL)
    func showAlert(message: String?, title: String?)
}

final class ProgressDolyamePresenter {
    
    // MARK: - Properties
    let configuration: PaymentConfiguration
    private let dolyamePollingService: PaymentPollingService
    private var currentPuid: String?
    weak var view: ProgressDolyameViewControllerProtocol?
    
    // MARK: - Init
    init(configuration: PaymentConfiguration, dolyamePollingService: PaymentPollingService = PaymentPollingServiceImpl()) {
        self.configuration = configuration
        self.dolyamePollingService = dolyamePollingService
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(intentDolyameObserverStatus(_:)),
            name: ObserverKeys.intentDolyameObserver.key,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopPolling()
    }
    
    // MARK: - Polling
    func stopPolling() {
        dolyamePollingService.stopPolling()
    }
    
    private func pollStatus() {
        CloudpaymentsApi.getIntentWaitStatus(configuration, type: .dolyame) { [weak self] statusCode in
            guard let self = self else { return }
            if statusCode == 200 {
                print("pollStatus: 200 — продолжаем опрос")
            } else {
                self.stopPolling()
                self.view?.showAlert(message: nil, title: .errorWordTitle)
            }
        }
    }
    
    private func startPolling() {
        stopPolling()
        dolyamePollingService.startPolling(taskName: .dolyameTransactionPolling, interval: 3) { [weak self] in
            guard let self = self else { return }
            self.pollStatus()
        }
    }
    
    // MARK: - Intent Status Handling
    @objc private func intentDolyameObserverStatus(_ notification: NSNotification) {
        guard let statusModel = notification.object as? PaymentTransactionStatusModel else {
            return
        }

        guard let intentStatusRaw = statusModel.status,
              let intentStatus = IntentWaitStatus(rawValue: intentStatusRaw) else {
            print("Статус интента невалиден")
            return
        }

        print("Статус интента при опросе транзакции: \(intentStatus.rawValue)")

        guard let puid = currentPuid,
              let transactions = statusModel.transactions else {
            return
        }
        
        let matchedTransactions = transactions.filter { $0.puid == puid }

        if matchedTransactions.isEmpty {
            print("Транзакции с текущим puid не найдены")
            return
        }

        for transaction in matchedTransactions {
            guard let transactionStatusRaw = transaction.status,
                  let intentTransactionStatus = IntentTransactionStatus(rawValue: transactionStatusRaw) else {
                print("Транзакция без статуса или с невалидным статусом")
                continue
            }

            print("Обработка транзакции — статус: \(intentTransactionStatus.rawValue)")
            handleIntentTransactionFinalStatus(intentTransactionStatus, transaction: transaction)
        }
        
        if intentStatus == .succeeded {
            stopPolling()
        }
    }
    
    // MARK: - Transaction Status Handling
    private func handleIntentTransactionFinalStatus(_ status: IntentTransactionStatus, transaction: PaymentTransactionResponse) {
        stopPolling()
        
        switch status {
        case .authorized, .completed:
            view?.resultPayment(result: .success, error: nil, transaction: transaction)
        case .declined, .cancelled:
            let errorMessage = ApiError.getFullErrorDescriptionIntentApi(from: transaction.code)
            view?.resultPayment(result: .error, error: errorMessage, transaction: transaction)
        }
    }
}

// MARK: - Input
extension ProgressDolyamePresenter {
    func getDolyameLinkIntentApi() {
        let puid = UUID().uuidString
        currentPuid = puid
        
        CloudpaymentsApi.getDolyameLinkIntentApi(puid: puid, configuration: configuration) { [weak self] statusCode, dolyameLink in
            guard let self = self else { return }
            
            switch statusCode {
            case 200:
                if let link = dolyameLink, let url = URL(string: link) {
                    self.view?.openLinkURL(url: url)
                    self.startPolling()
                } else {
                    self.view?.showAlert(message: nil, title: .banksAppNotOpen)
                }
            case 409:
                self.view?.resultPayment(result: .success, error: .orderAlreadyBeenPaid, transaction: nil)
            default:
                self.view?.showAlert(message: nil, title: .errorWordTitle)
            }
        }
    }
}
