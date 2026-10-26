//
//  AnalyticsDataEvents.swift
//  sdk
//
//  Created by Cloudpayments on 21.10.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import Foundation

// MARK: - Event

struct AnalyticsEvent: Codable {
    let kind: String?
    let project: String
    let name: String?
    let parameters: AnalyticsEventParameters?
    let eventParameters: AnalyticsEventMeta
    let clientParameters: AnalyticsClientMeta
    let userProperties: AnalyticsUserPropertiesWrapper?
}

struct AnalyticsActionEvent: Codable {
    let project: String
    let name: String?
    let parameters: AnalyticsActionParameters
    let eventParameters: AnalyticsEventMeta
    let clientParameters: AnalyticsClientMeta
}

// MARK: - Parameters

struct AnalyticsEventParameters: Codable {
    let eventType: String?
    let screenName: String?
    let cardFieldsCount: Int
    let methodsAvailable: [String]?
    let methodsDisplayed: [String]?
    let methodChosen: String?
    let context: String?
}

struct AnalyticsActionParameters: Codable {
    let screenName: String
    let elementLabel: String
    let elementType: String
    let actionType: String
    let methodChosen: String?
    let context: String?
}

// MARK: - Meta

struct AnalyticsEventMeta: Codable {
    let clientEventTimestamp: Int64
    let clientUploadTimestamp: Int64
    let sequence: Int
    let uuid: String
}

struct AnalyticsClientMeta: Codable {
    let sessionId: String?
    let deviceId: String?
    let sessionStartTime: Int64
    let pageUrl: String
}

// MARK: - User properties

struct AnalyticsUserPropertiesWrapper: Codable {
    let set: AnalyticsUserPropertiesPayload
    enum CodingKeys: String, CodingKey { case set = "$set" }
}

struct AnalyticsUserPropertiesPayload: Codable {
    let project: String
    let region: String
    let publicId: String
    let intentId: String
    let terminalIsTest: Bool
    let saveCard: Bool
    let forceSaveCard: Bool
    let sendToEmail: Bool
    let forceSendToEmail: Bool
    let isRecurring: Bool
    let isStatic: Bool
}
