//
//  ProgressDRAssembly.swift
//  sdk
//
//  Created by Cloudpayments on 30.09.2026.
//  Copyright © 2026 Cloudpayments. All rights reserved.
//

import Foundation

public class DRAssembly {
    class func createDRVC(configuration: PaymentConfiguration) -> ProgressDRViewController {
        let presenter = ProgressDRPresenter(configuration: configuration)
        let view = ProgressDRViewController(presenter: presenter)
        presenter.view = view
        return view
    }
}
