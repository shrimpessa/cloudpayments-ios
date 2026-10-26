//
//  SbpDataResponse.swift
//  sdk
//
//  Created by Cloudpayments on 02.07.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

struct SbpDataResponse: Codable {
    let model: AltPayTransactionResponse
    let success: Bool
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case model = "Model"
        case success = "Success"
        case message = "Message"
    }
}
