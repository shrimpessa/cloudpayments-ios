//
//  SbpData.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 26.07.2023.
//

import Foundation

struct SbpBanksList: Codable {
    let version: String
    var dictionary: [SbpData]
}

struct SbpData: Codable {
    let bankName: String?
    let logoURL: String?
    let schema: String
    let packageName: String?
    let webClientURL: String?
    let isWebClientActive: String?

    enum CodingKeys: String, CodingKey {
        case bankName, logoURL, schema
        case packageName = "package_name"
        case webClientURL = "webClientUrl"
        case isWebClientActive
    }
    
    var deeplink: URL? {
        return URL(string: schema + "://qr.nspk.ru/")
    }
}
