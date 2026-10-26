//
//  ProgressTPayAssembly.swift
//  sdk
//
//  Created by Cloudpayments on 16.11.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import Foundation

public class TpayAssembly {
    class func createTPayVC(configuration: PaymentConfiguration) -> ProgressTPayViewController {
        let presenter = ProgressTPayPresenter(configuration: configuration)
        let view = ProgressTPayViewController(presenter: presenter)
        presenter.view = view
        return view
    }
}
