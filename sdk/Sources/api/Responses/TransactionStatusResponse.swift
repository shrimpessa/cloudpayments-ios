//
//  TransactionStatusResponse.swift
//  sdk
//
//  Created by Cloudpayments on 02.07.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

struct TransactionStatusResponse: Codable {
    let success: Bool?
    let message: String?
    let model: TransactionStatus?
    
    enum CodingKeys: String, CodingKey {
        case success = "Success"
        case message = "Message"
        case model = "Model"
    }
}

struct TransactionStatus: Codable {
    let transactionId: Int64?
    let status: StatusPay.RawValue?
    let statusCode: Int?
    let providerQrId: String?
    
    enum CodingKeys: String, CodingKey {
        case transactionId = "TransactionId"
        case status = "Status"
        case statusCode = "StatusCode"
        case providerQrId = "ProviderQrId"
    }
}
