//
//  ExternalPaymentMethod.swift
//  sdk
//
//  Created by Cloudpayments on 02.07.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

struct ExternalPaymentMethod: Codable {
    let type: CaseOfBank.RawValue?
    let enabled: Bool
    let appleMerchantID: String?
    let allowedPaymentMethods: [String]?
    let shopID, showCaseID: String?

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case enabled = "Enabled"
        case appleMerchantID = "AppleMerchantId"
        case allowedPaymentMethods = "AllowedPaymentMethods"
        case shopID = "ShopId"
        case showCaseID = "ShowCaseId"
    }
}
