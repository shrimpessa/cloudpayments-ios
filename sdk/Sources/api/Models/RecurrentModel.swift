//
//  RecurrentModel.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 10.07.2023.
//

import Foundation

public struct Recurrent {
    public let amount: Decimal?
    public let interval: String
    public let period: Int
    public let startDate: String?
    public let maxPeriods: Int?
    public let receipt: [String: Any]?
    
    public init(interval: String, period: Int, receipt: [String: Any]? = nil, amount: Decimal? = nil, startDate: String? = nil, maxPeriods: Int? = nil) {
        self.interval = interval
        self.period = period
        self.receipt = receipt
        self.amount = amount
        self.startDate = startDate
        self.maxPeriods = maxPeriods
    }
}

extension Recurrent {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "interval": interval,
            "period": period
        ]
        
        if let receipt = receipt {
            dict["receipt"] = receipt
        }
        if let amount = amount {
            dict["amount"] = amount
        }
        if let startDate = startDate {
            dict["startDate"] = startDate
        }
        if let maxPeriods = maxPeriods {
            dict["maxPeriods"] = maxPeriods
        }
        
        return dict
    }
}
