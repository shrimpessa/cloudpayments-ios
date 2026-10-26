//
//  IntentPatchById.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import Foundation
import CloudpaymentsNetworking

final class IntentPatchById: BaseRequest, CloudpaymentsRequestType {
    typealias ResponseType = PaymentIntentResponse

    private let intentId: String

    init(patchBody: Data, intentId: String, apiUrl: String, headers: [String: String]) {
        self.intentId = intentId
        super.init(
            queryItems: [:],
            headers: headers,
            apiUrl: apiUrl,
            body: patchBody
        )
    }

    var data: CloudpaymentsRequest {
        let fullUrl = "\(apiUrl)api/intent/\(intentId)"
        return CloudpaymentsRequest(
            path: fullUrl,
            method: .patch,
            headers: headers,
            body: body
        )
    }
}
