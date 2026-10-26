//
//  WhiteTextField.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit

final class WhiteTextFieldComponent: UITextField {
    private let padding = UIEdgeInsets(top: 8, left: 4, bottom: 0, right: 0)
    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }
    private func setup() {
        backgroundColor = .white
        borderStyle = .none
        textAlignment = .left
        font = .systemFont(ofSize: 15, weight: .regular)
        textColor = .mainText
        autocorrectionType = .no
        spellCheckingType = .no
        autocapitalizationType = .none
    }
    override func textRect(forBounds b: CGRect) -> CGRect { b.inset(by: padding) }
    override func editingRect(forBounds b: CGRect) -> CGRect { b.inset(by: padding) }
    override func placeholderRect(forBounds b: CGRect) -> CGRect { b.inset(by: padding) }
}
