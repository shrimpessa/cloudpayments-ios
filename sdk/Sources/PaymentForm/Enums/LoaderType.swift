//
//  LoaderType.swift
//  sdk
//
//  Created by Cloudpayments on 14.09.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import Foundation

public enum LoaderType: String {
    case loaderText = "Загружаем способы оплаты"
    case loadingBanks = "Загружаем список банков"
    
    public func toString() -> String {
        return self.rawValue
    }
}
