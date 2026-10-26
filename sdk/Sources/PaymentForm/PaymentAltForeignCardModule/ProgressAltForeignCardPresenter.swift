//
//  ProgressAltForeignCardPresenter.swift
//  sdk
//
//  Created by Cloudpayments on 10.06.2026.
//  Copyright © 2026 Cloudpayments. All rights reserved.
//

import Foundation

protocol ProgressAltForeignCardViewControllerProtocol: AnyObject {
    func resultPayment(result: PaymentResultAction, error: String?, transaction: PaymentTransactionResponse?)
    func openLinkURL(url: URL)
    func showAlert(message: String?, title: String?)
}

final class ProgressAltForeignCardPresenter {
    
    // MARK: - Properties
    let configuration: PaymentConfiguration
    private let altForeignCardPollingService: PaymentPollingService
    private var currentPuid: String?
    weak var view: ProgressAltForeignCardViewControllerProtocol?
    
    // MARK: - Init
    init(configuration: PaymentConfiguration, altForeignCardPollingService: PaymentPollingService = PaymentPollingServiceImpl()) {
        self.configuration = configuration
        self.altForeignCardPollingService = altForeignCardPollingService
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(intentAltForeingCardObserverStatus(_:)),
            name: ObserverKeys.intentAltForeignCardObserver.key,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopPolling()
    }
    
    // MARK: - Polling
    func stopPolling() {
        altForeignCardPollingService.stopPolling()
    }
    
    private func pollStatus() {
        CloudpaymentsApi.getIntentWaitStatus(configuration, type: .foreignCard) { [weak self] statusCode in
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
        altForeignCardPollingService.startPolling(taskName: .altForeignCardTransactionPolling, interval: 3) { [weak self] in
            guard let self = self else { return }
            self.pollStatus()
        }
    }
    
    // MARK: - Intent Status Handling
    @objc private func intentAltForeingCardObserverStatus(_ notification: NSNotification) {
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
extension ProgressAltForeignCardPresenter {
    func getAltForeignCardLinkIntentApi() {
        let puid = UUID().uuidString
        currentPuid = puid
        
        CloudpaymentsApi.getAltForeignCardLinkIntentApi(puid: puid, configuration: configuration) { [weak self] statusCode, altForeignCardLink in
            guard let self = self else { return }
            
            switch statusCode {
            case 200:
                if let link = altForeignCardLink, let url = URL(string: link) {
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
