//
//  AnalyticsService.swift
//  sdk
//
//  Created by Cloudpayments on 21.10.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import Foundation
import UIKit

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private let analyticsURLString = "https://as.tbank.ru/gateway/v1/events"
    private var sessionStartTime: Int64?
    private var cachedDeviceId: String?
    private var currentSequence: Int = 0
    private var cachedSessionId: String?
    
    private init() {}
    
    func startSession() {
        
        sessionStartTime = Int64(Date().timeIntervalSince1970 * 1000)
        cachedSessionId = UUID().uuidString.lowercased()
        
        if cachedDeviceId == nil {
            cachedDeviceId = UIDevice.current.identifierForVendor?.uuidString.lowercased() ?? "DeviceId not created"
        }
        
        currentSequence = 0
        print("------------>>>>> Analytics session started — DeviceID: \(cachedDeviceId ?? ""), SessionID: \(cachedSessionId ?? "")")
    }
    
    private func nextSequence() -> Int {
        currentSequence += 1
        return currentSequence
    }
    
    private func buildContext(configuration: PaymentConfiguration) -> (
        timestamp: Int64,
        deviceId: String?,
        sessionId: String?,
        sessionStart: Int64
    ) {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let deviceId = cachedDeviceId ?? "DeviceId not created"
        let sessionId = cachedSessionId ?? UUID().uuidString.lowercased()
        let sessionStart = sessionStartTime ?? timestamp
        return (timestamp, deviceId, sessionId, sessionStart)
    }
    
    func sendPaymentMethodsStartSessionEvent(
        configuration: PaymentConfiguration,
        intent: PaymentIntentResponse,
        methodsAvailable: [String],
        displayedMethods: [String]
    ) {
        let context = buildContext(configuration: configuration)
        let project = "mobileSDK"
        let region = "RU"
        let publicId = configuration.publicId
        let intentId = intent.id ?? "IntentId not created"
        let terminalIsTest = intent.terminalInfo?.isTest ?? false
        let saveCard = intent.tokenize ?? false
        let forceSaveCard = configuration.paymentData.intentSaveCardState == .force
        let sendToEmail = !(configuration.paymentData.email.isNilOrEmpty)
        let forceSendToEmail = configuration.emailBehavior == .required
        let isRecurring = configuration.paymentData.recurrent != nil
        let isStatic = false
        
        let userProperties = AnalyticsUserPropertiesWrapper(
            set: .init(
                project: project,
                region: region,
                publicId: publicId,
                intentId: intentId,
                terminalIsTest: terminalIsTest,
                saveCard: saveCard,
                forceSaveCard: forceSaveCard,
                sendToEmail: sendToEmail,
                forceSendToEmail: forceSendToEmail,
                isRecurring: isRecurring,
                isStatic: isStatic
            )
        )
        
        let userPropertiesEvent = AnalyticsEvent(
            kind: "userProperties",
            project: "cloud.payments.mpf",
            name: nil,
            parameters: nil,
            eventParameters: .init(
                clientEventTimestamp: context.timestamp,
                clientUploadTimestamp: context.timestamp,
                sequence: nextSequence(),
                uuid: UUID().uuidString.lowercased()
            ),
            clientParameters: .init(
                sessionId: context.sessionId,
                deviceId: context.deviceId,
                sessionStartTime: context.sessionStart,
                pageUrl: "iOS SDK"
            ),
            userProperties: userProperties
        )
        CloudpaymentsApi.post(to: analyticsURLString, body: [userPropertiesEvent])
        
        let event = AnalyticsEvent(
            kind: nil,
            project: "cloud.payments.mpf",
            name: "events.system",
            parameters: .init(
                eventType: "Open",
                screenName: "/methods",
                cardFieldsCount: 0,
                methodsAvailable: methodsAvailable,
                methodsDisplayed: displayedMethods,
                methodChosen: nil,
                context: nil
            ),
            eventParameters: .init(
                clientEventTimestamp: context.timestamp,
                clientUploadTimestamp: context.timestamp,
                sequence: nextSequence(),
                uuid: UUID().uuidString.lowercased()
            ),
            clientParameters: .init(
                sessionId: context.sessionId,
                deviceId: context.deviceId,
                sessionStartTime: context.sessionStart,
                pageUrl: "iOS SDK"
            ),
            userProperties: nil
        )
        CloudpaymentsApi.post(to: analyticsURLString, body: [event])
    }
    
    func sendPaymentMethodsScreenOpenedAgain(configuration: PaymentConfiguration) {
        let context = buildContext(configuration: configuration)
        let methodsAvailable = configuration.paymentData.methodsAvailable ?? []
        
        let event = AnalyticsEvent(
            kind: nil,
            project: "cloud.payments.mpf",
            name: "events.system",
            parameters: .init(
                eventType: "Open",
                screenName: "Start",
                cardFieldsCount: 0,
                methodsAvailable: methodsAvailable,
                methodsDisplayed: nil,
                methodChosen: nil,
                context: nil
            ),
            eventParameters: .init(
                clientEventTimestamp: context.timestamp,
                clientUploadTimestamp: context.timestamp,
                sequence: nextSequence(),
                uuid: UUID().uuidString.lowercased()
            ),
            clientParameters: .init(
                sessionId: context.sessionId,
                deviceId: context.deviceId,
                sessionStartTime: context.sessionStart,
                pageUrl: "iOS SDK"
            ),
            userProperties: nil
        )
        CloudpaymentsApi.post(to: analyticsURLString, body: [event])
    }
    
    func sendActionClickEvent(configuration: PaymentConfiguration,
                              elementLabel: String,
                              elementType: String,
                              actionType: String,
                              screenName: String,
                              methodChosen: String? = nil,
                              actionContext: String? = nil) {
        let context = buildContext(configuration: configuration)
        
        let event = AnalyticsActionEvent(
            project: "cloud.payments.mpf",
            name: "events.action",
            parameters: .init(
                screenName: screenName,
                elementLabel: elementLabel,
                elementType: elementType,
                actionType: actionType,
                methodChosen: methodChosen,
                context: actionContext
            ),
            eventParameters: .init(
                clientEventTimestamp: context.timestamp,
                clientUploadTimestamp: context.timestamp,
                sequence: nextSequence(),
                uuid: UUID().uuidString.lowercased()
            ),
            clientParameters: .init(
                sessionId: context.sessionId,
                deviceId: context.deviceId,
                sessionStartTime: context.sessionStart,
                pageUrl: "iOS SDK"
            )
        )
        CloudpaymentsApi.post(to: analyticsURLString, body: [event])
    }
    
    func sendScreenOpenedEvent(configuration: PaymentConfiguration,
                               screenName: String,
                               methodsAvailable: [String]? = nil,
                               methodChosen: String? = nil,
                               cardFieldsCount: Int,
                               eventType: String,
                               errorContext: String? = nil) {
        let context = buildContext(configuration: configuration)
        let event = AnalyticsEvent(
            kind: nil,
            project: "cloud.payments.mpf",
            name: "events.system",
            parameters: .init(
                eventType: eventType,
                screenName: screenName,
                cardFieldsCount: cardFieldsCount,
                methodsAvailable: methodsAvailable,
                methodsDisplayed: nil,
                methodChosen: methodChosen,
                context: errorContext
            ),
            eventParameters: .init(
                clientEventTimestamp: context.timestamp,
                clientUploadTimestamp: context.timestamp,
                sequence: nextSequence(),
                uuid: UUID().uuidString.lowercased()
            ),
            clientParameters: .init(
                sessionId: context.sessionId,
                deviceId: context.deviceId,
                sessionStartTime: context.sessionStart,
                pageUrl: "iOS SDK"
            ),
            userProperties: nil
        )
        CloudpaymentsApi.post(to: analyticsURLString, body: [event])
    }
}
