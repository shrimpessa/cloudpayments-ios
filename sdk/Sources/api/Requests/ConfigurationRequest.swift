//
//  ConfigurationRequest.swift
//  sdk
//
//  Created by Cloudpayments on 15.11.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import Foundation
import CloudpaymentsNetworking

final class ConfigurationRequest: BaseRequest, CloudpaymentsRequestType {
    typealias ResponseType = MerchantConfigurationResponse
    var data: CloudpaymentsRequest {
        let path = CloudpaymentsHTTPResource.configuration.asUrl(apiUrl: apiUrl)
       
        guard var component = URLComponents(string: path) else { return CloudpaymentsRequest(path: path, headers: headers) }
       
        if !queryItems.isEmpty {
            let items = queryItems.compactMap { return URLQueryItem(name: $0, value: $1) }
            component.queryItems = items
        }
        
        guard let url = component.url else { return CloudpaymentsRequest(path: path, headers: headers) }
        let fullPath = url.absoluteString
        
        return CloudpaymentsRequest(path: fullPath, headers: headers)
    }
}
