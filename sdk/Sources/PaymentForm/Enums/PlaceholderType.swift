//
//  PlaceholderType.swift
//  sdk
//
//  Created by Cloudpayments on 19.09.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import Foundation

enum PlaceholderType: String {
    case correctCard = "Номер карты"
    case incorrectCard = "Некорректный номер карты"
    case correctExpDate = "Cрок действия"
    case incorrectExpDate = "Ошибка в cроке"
    case correctCvv = "СVV/СVC"
    case incorrectCvv = "Ошибка в CVV/СVC"
    
    func toString() -> String {
        return self.rawValue
    }
}
