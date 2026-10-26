//
//  NameCardType.swift
//  sdk
//
//  Created by Cloudpayments on 02.07.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

enum NameCardType: String, Codable {
    case unknown = "Unknown"
    case visa = "Visa"
    case masterCard = "MasterCard"
    case maestro = "Maestro"
    case mir = "MIR"
    case jcb = "Jcb"
    case jcb15 = "Jcb15"
    case americanExpress = "AmericanExpress"
    case troy = "Troy"
    case dankort = "Dankort"
    case discover = "Discover"
    case diners = "Diners"
    case instapayments = "Instapayments"
    case humo = "Humo"
    case uatp = "Uatp"
    case unionPay = "UnionPay"
    case uzcard = "Uzcard"
    
    var string: String {
        switch self {
        case .jcb, .jcb15: return NameCardType.jcb.rawValue
        default: return rawValue
        }
    }
}
