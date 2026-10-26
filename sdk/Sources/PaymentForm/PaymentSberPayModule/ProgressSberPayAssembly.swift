//
//  ProgressSberPayAssembly.swift
//  sdk
//
//  Created by Cloudpayments on 20.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation

public class ProgressSberPayAssembly {
    class func createSberPayVC(configuration: PaymentConfiguration) -> ProgressSberPayViewController {
        let presenter = ProgressSberPayPresenter(configuration: configuration)
        let view = ProgressSberPayViewController(presenter: presenter)
        presenter.view = view
        return view
    }
}
