//
//  ValidState.swift
//  sdk
//
//  Created by Cloudpayments on 19.09.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import Foundation
import UIKit

enum ValidState {
    case border
    case error
    case normal
    case text
    
    var color: UIColor {
        switch self {
        case .border:
            return .border
        case .error:
            return .errorBorder
        case .normal:
            return .mainBlue
        case .text:
            return .mainText
        }
    }
}
