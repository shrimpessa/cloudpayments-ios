//
//  Features.swift
//  sdk
//
//  Created by Cloudpayments on 02.07.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

struct Features: Codable {
    let isAllowedNotSanctionedCards, isQiwi: Bool
    let isSaveCard: Int

    enum CodingKeys: String, CodingKey {
        case isAllowedNotSanctionedCards = "IsAllowedNotSanctionedCards"
        case isQiwi = "IsQiwi"
        case isSaveCard = "IsSaveCard"
    }
}
