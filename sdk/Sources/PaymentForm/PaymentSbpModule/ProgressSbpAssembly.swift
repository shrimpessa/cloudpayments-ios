//
//  ProgressSbpAssembly.swift
//  sdk
//
//  Created by Cloudpayments on 02.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation
import UIKit

final class SbpAssembly {
    class func createSbpVC(configuration: PaymentConfiguration, from: UIViewController) -> ProgressSbpViewController {
        let presenter = ProgressSbpPresenter(configuration: configuration)
        let view = ProgressSbpViewController(presenter: presenter)
        presenter.view = view
        return view
    }
}
