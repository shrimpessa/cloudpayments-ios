//
//  PaymentMethodType.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

public enum PaymentMethodType: String, CaseIterable {
    case tpay = "TinkoffPay"
    case sberPay = "SberPay"
    case sbp = "Sbp"
    case card = "Card"
    case foreignCard = "ForeignCard"
    case dolyame = "Dolyame"
    case tInstallment = "TcsInstallment"
    case dr = "DR"
}

extension PaymentMethodType {
    
    var buttonTitle: String? {
        switch self {
        case .card:
            return "Банковская карта"
        case .foreignCard:
            return nil
        case .tpay, .sbp, .sberPay, .dolyame:
            return nil
        case .tInstallment:
            return "Купить в рассрочку"
        case .dr: return "Цифровым рублем"
        }
    }
    
    var buttonIcon: UIImage? {
        switch self {
        case .card: return nil
        case .foreignCard: return .iconForeignCard
        case .tpay: return .iconTPay
        case .sbp: return .iconSbp
        case .sberPay: return .iconSberPay
        case .dolyame: return .iconDolyame
        case .tInstallment: return .iconTInstalment
        case .dr: return .iconDr
        }
    }
    
    var additionalButtonIcon: UIImage? {
        switch self {
        case .card: return .iconCardAdditional
        case .foreignCard: return .iconForeignCardAdditional
        case .tpay: return .iconTpayAdditional
        case .sbp: return .iconSbpAdditional
        case .sberPay: return .iconSberPayAdditional
        case .dolyame: return .iconDolyameAdditional
        case .tInstallment: return .iconTInstalmentAdditional
        case .dr: return .iconDrAdditional
        }
    }
    
    var backgroundColor: UIColor? {
        switch self {
        case .card: return .colorBlue
        case .foreignCard: return .clear
        case .tpay: return .tpayButtonColor
        case .sbp: return .sbpButtonColor
        case .sberPay: return .sberPayButtonColor
        case .dolyame: return .black
        case .tInstallment: return .tInstallmentButtonColor
        case .dr: return .drButtonColor
        }
    }
    
    var titleText: String {
        switch self {
        case .sberPay: return .payResponseSberPay
        case .tpay: return .payResponseTPay
        case .sbp: return .payResponseSbp
        case .card: return .payResponseCardPay
        case .foreignCard: return .payResponseAltForeignCard
        case .dolyame: return .payResponseDolyame
        case .tInstallment: return .payResponseTInstallment
        case .dr: return .payResponseCardPay
        }
    }
    
    var methodLogoImage: UIImage? {
        switch self {
        case .card: return nil
        case .foreignCard: return nil
        case .tpay: return .iconTPay
        case .sberPay: return .iconMethodSberPay
        case .sbp: return nil
        case .dolyame: return .iconMethodDolyame
        case .tInstallment: return nil
        case .dr: return nil
        }
    }
}
