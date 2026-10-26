//
//  ProgressTInstallmentPresenter.swift
//  sdk
//
//  Created by Cloudpayments on 13.07.2026.
//  Copyright © 2026 Cloudpayments. All rights reserved.
//

import Foundation

protocol ProgressTInstallmentViewControllerProtocol: AnyObject {
    func resultPayment(result: PaymentResultAction, error: String?, transaction: PaymentTransactionResponse?)
    func openLinkURL(url: URL)
    func showAlert(message: String?, title: String?)
}

final class ProgressTInstallmentPresenter {
    
    let configuration: PaymentConfiguration
    private let tInstallmentPollingService: PaymentPollingService
    private var currentPuid: String?
    weak var view: ProgressTInstallmentViewControllerProtocol?
    
    init(
        configuration: PaymentConfiguration,
        tInstallmentPollingService: PaymentPollingService = PaymentPollingServiceImpl()
    ) {
        self.configuration = configuration
        self.tInstallmentPollingService = tInstallmentPollingService
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(intentTInstallmentObserverStatus(_:)),
            name: ObserverKeys.intentTInstallmentObserver.key,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopPolling()
    }
    
    func stopPolling() {
        tInstallmentPollingService.stopPolling()
    }
    
    private func pollStatus() {
        CloudpaymentsApi.getIntentWaitStatus(configuration, type: .tInstallment) { [weak self] statusCode in
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
        tInstallmentPollingService.startPolling(taskName: .tInstallmentTransactionPollingService, interval: 3) { [weak self] in
            guard let self = self else { return }
            self.pollStatus()
        }
    }
    
    @objc private func intentTInstallmentObserverStatus(_ notification: NSNotification) {
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
extension ProgressTInstallmentPresenter {
    func getTInstallmentLinkIntentApi() {
        let puid = UUID().uuidString
        currentPuid = puid
        
        let period = configuration.paymentData.selectedTInstallmentPeriod
        
        CloudpaymentsApi.getTInstallmentLinkIntentApi(
            puid: puid,
            period: period,
            configuration: configuration
        ) { [weak self] statusCode, tInstallmentLink in
            guard let self = self else { return }
            
            switch statusCode {
            case 200:
                if let link = tInstallmentLink, let url = URL(string: link) {
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
