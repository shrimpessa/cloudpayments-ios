//
//  UIApplication+Extensions.swift
//  sdk
//
//  Created by Cloudpaymentson 14.09.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import UIKit

extension UIApplication {
    class func topViewController(
        controller: UIViewController? = UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)?
            .rootViewController
    ) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        
        if let tabBarController = controller as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topViewController(controller: selectedViewController)
        }
        
        if let presentedViewController = controller?.presentedViewController {
            return topViewController(controller: presentedViewController)
        }
        
        return controller
    }
}
