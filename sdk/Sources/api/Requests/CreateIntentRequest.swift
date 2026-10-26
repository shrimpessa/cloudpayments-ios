//
//  CreateIntentRequest.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import Foundation
import CloudpaymentsNetworking

final class CreateIntentRequest: BaseRequest, CloudpaymentsRequestType {
    typealias ResponseType = PaymentIntentResponse
    var data: CloudpaymentsRequest {
        let path = CloudpaymentsHTTPResource.apiIntent.asUrl(apiUrl: apiUrl)
       
        guard var component = URLComponents(string: path) else { return CloudpaymentsRequest(path: path, method: .post, params: params, headers: headers) }
       
        if !queryItems.isEmpty {
            let items = queryItems.compactMap { return URLQueryItem(name: $0, value: $1) }
            component.queryItems = items
        }
        
        guard let url = component.url else { return CloudpaymentsRequest(path: path, method: .post, params: params, headers: headers) }
        let fullPath = url.absoluteString
        print(fullPath)
        
        return CloudpaymentsRequest(path: fullPath, method: .post, params: params, headers: headers)
    }
}
