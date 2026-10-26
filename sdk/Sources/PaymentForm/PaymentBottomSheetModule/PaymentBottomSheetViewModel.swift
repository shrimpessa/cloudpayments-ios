//
//  PaymentBottomSheetViewModel.swift
//  sdk
//
//  Created by Cloudpayments on 20.05.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit

// MARK: — ViewModel

protocol BottomSheetViewModelProtocol {
    var cornerRadius: CGFloat { get }
    var closeThresholdRatio: CGFloat { get }

    func handlePan(translationY: CGFloat, velocityY: CGFloat) -> BottomSheetViewModel.PanResult
}

final class BottomSheetViewModel: BottomSheetViewModelProtocol {
    enum PanResult {
        case animateToOpen
        case animateToClose
        case updateY(CGFloat)
    }
    
    let cornerRadius: CGFloat
    let closeThresholdRatio: CGFloat = 0.3
    
    init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }
    
    func handlePan(translationY: CGFloat, velocityY: CGFloat) -> PanResult {
        if abs(velocityY) < 1000 {
            return .updateY(translationY)
        }
        return velocityY > 0 ? .animateToClose : .animateToOpen
    }
}
