//
//  PaymentOptionsViewModel.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

final class BottomSheetPaymentOptionsViewModel {
    
    enum PaymentIntentError: Error {
        case missingPublicKey
        case intentNotCreated
    }
    
    let configuration: PaymentConfiguration
    
    init(configuration: PaymentConfiguration) {
        self.configuration = configuration
    }
    
    func loadPublicKeyAndCreateIntent(
        completion: @escaping (Result<([PaymentMethod], [String]?, PaymentIntentResponse), Error>) -> Void
    ) {
        CloudpaymentsApi.getPublicKey { [weak self] publicKey, _ in
            guard let self else { return }
            guard let pem = publicKey?.Pem, let version = publicKey?.Version else {
                completion(.failure(PaymentIntentError.missingPublicKey))
                return
            }
            
            configuration.paymentData.pem = pem
            configuration.paymentData.version = version
            
            let bodySequence = configuration.paymentMethodSequence.map { $0.rawValue }
            
            CloudpaymentsApi.createIntent(
                with: configuration,
                paymentMethodSequence: bodySequence
            ) { [weak self] responseIntent in
                guard let self, let intent = responseIntent else {
                    completion(.failure(PaymentIntentError.intentNotCreated))
                    return
                }
                
                configuration.paymentData.intentId = intent.id
                configuration.paymentData.secret = intent.secret
                
                var methods = intent.paymentMethods ?? []
                let intentPaymentMethodSequence = intent.paymentMethodSequence
                
                if let sequence = intentPaymentMethodSequence, !sequence.isEmpty {
                    var prioritized: [PaymentMethod] = []
                    
                    for type in sequence {
                        if let method = methods.first(where: { $0.type == type }) {
                            prioritized.append(method)
                        }
                    }
                    
                    for method in methods where !sequence.contains(method.type ?? "") {
                        prioritized.append(method)
                    }
                    
                    methods = prioritized
                }
                
                savePaymentLinks(from: methods)
                configuration.paymentData.cachedMethods = methods
                
                let terminalUrl = intent.terminalInfo?.terminalFullUrl
                configuration.paymentData.terminalFullUrl = terminalUrl
                
                if configuration.successRedirectUrl.isNilOrEmpty {
                    configuration.successRedirectUrl = terminalUrl
                }
                if configuration.failRedirectUrl.isNilOrEmpty {
                    configuration.failRedirectUrl = terminalUrl
                }
                
                let needPatch = intent.successRedirectUrl.isNilOrEmpty || intent.failRedirectUrl.isNilOrEmpty
                if needPatch {
                    let patch = PatchBuilder.make {
                        if let successRedirectUrl = self.configuration.successRedirectUrl {
                            $0.replace("/successRedirectUrl", value: successRedirectUrl)
                        }
                        if let failRedirectUrl = self.configuration.failRedirectUrl {
                            $0.replace("/failRedirectUrl", value: failRedirectUrl)
                        }
                    }
                    
                    CloudpaymentsApi.intentPatchById(configuration: configuration, patches: patch) { result in
                        print("PATCH result: success: \(String(describing: result?.successRedirectUrl)), fail: \(String(describing: result?.failRedirectUrl))")
                    }
                }
                
                let isSaveCard = intent.terminalInfo?.features?.isSaveCard
                let tokenize = intent.tokenize
                
                if let rawState = isSaveCard,
                   let saveState = IntentSaveCardState(rawValue: rawState) {
                    configuration.paymentData.intentSaveCardState = saveState
                    configuration.paymentData.savedTokenize = tokenize
                }
                
                completion(.success((methods, intentPaymentMethodSequence, intent)))
            }
        }
    }
    
    private func savePaymentLinks(from methods: [PaymentMethod]) {        
        for method in methods {
            guard let typeString = method.type,
                  let type = PaymentMethodType(rawValue: typeString) else {
                continue
            }
            
            switch type {
            case .tpay:
                if let link = method.link {
                    configuration.paymentData.paymentLinks[type.rawValue] = link
                    print("Сохранили link для TPay: \(link)")
                }
                
            case .sberPay:
                if let data = method.data {
                    configuration.paymentData.sberPayData = data
                    print("Сохранили data для SberPay")
                }
                
            case .sbp:
                if let link = method.link {
                    configuration.paymentData.paymentLinks[type.rawValue] = link
                    print("Сохранили link для Sbp: \(link)")
                }
                if let banks = method.banks {
                    configuration.paymentData.sbpBanks = banks
                    print("Сохранили банки для Sbp: \(banks.count)")
                }
                
            case .dolyame:
                if let link = method.link {
                    configuration.paymentData.paymentLinks[type.rawValue] = link
                    print("Сохранили link для Dolyame: \(link)")
                }
                
            case .foreignCard:
                if let link = method.link {
                    configuration.paymentData.paymentLinks[type.rawValue] = link
                    print("Сохранили link для альтовой ForeignCard: \(link)")
                }
                
            case .card:
                print("Card: link не сохраняем")
            case .tInstallment:
                if let link = method.link {
                    configuration.paymentData.paymentLinks[type.rawValue] = link
                    print("Сохранили link для рассрочки: \(link)")
                }
                configuration.paymentData.periods = method.periods ?? []
                print("Сохранили периоды: \(configuration.paymentData.periods)")
            case .dr:
                if let link = method.link {
                    configuration.paymentData.paymentLinks[type.rawValue] = link
                    print("Сохранили link для цифрового рубля: \(link)")
                }
            }
        }
    }
}
