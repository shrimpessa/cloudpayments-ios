//
//  MerchantConfigurationResponse.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 16.06.2023.
//

import Foundation

public struct MerchantConfigurationResponse: Codable {
    let model: MerchantConfiguration
    let success: Bool
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case model = "Model"
        case success = "Success"
        case message = "Message"
    }
}

struct MerchantConfiguration: Codable {
    let logoURL: String?
    let terminalURL: String?
    let terminalFullUrl: String?
    let widgetURL: String?
    let isCharity, isTest: Bool?
    let terminalName: String?
    let skipExpiryValidation: Bool?
    let agreementPath: String?
    let isCvvRequired: Bool?
    let externalPaymentMethods: [ExternalPaymentMethod]
    let features: Features?
    let supportedCards: [Int]?

    enum CodingKeys: String, CodingKey {
        case logoURL = "LogoUrl"
        case terminalURL = "TerminalUrl"
        case terminalFullUrl = "TerminalFullUrl"
        case widgetURL = "WidgetUrl"
        case isCharity = "IsCharity"
        case isTest = "IsTest"
        case terminalName = "TerminalName"
        case skipExpiryValidation = "SkipExpiryValidation"
        case agreementPath = "AgreementPath"
        case isCvvRequired = "IsCvvRequired"
        case externalPaymentMethods = "ExternalPaymentMethods"
        case features = "Features"
        case supportedCards = "SupportedCards"
    }
}
