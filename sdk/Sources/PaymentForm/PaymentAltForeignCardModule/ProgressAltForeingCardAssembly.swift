//
//  ProgressAltForeingCardAssembly.swift
//  sdk
//
//  Created by Cloudpayments on 10.06.2026.
//  Copyright © 2026 Cloudpayments. All rights reserved.
//

import Foundation

public class AltForeingCardAssembly {
    class func createAltForeignCardVC(configuration: PaymentConfiguration) -> ProgressAltForeignCardViewController {
        let presenter = ProgressAltForeignCardPresenter(configuration: configuration)
        let view = ProgressAltForeignCardViewController(presenter: presenter)
        presenter.view = view
        return view
    }
}
