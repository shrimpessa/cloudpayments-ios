//
//  ProgressDolyameAssembly.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import Foundation

public class DolyameAssembly {
    class func createDolyameVC(configuration: PaymentConfiguration) -> ProgressDolyameViewController {
        let presenter = ProgressDolyamePresenter(configuration: configuration)
        let view = ProgressDolyameViewController(presenter: presenter)
        presenter.view = view
        return view
    }
}
