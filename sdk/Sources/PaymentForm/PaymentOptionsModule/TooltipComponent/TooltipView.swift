//
//  TooltipView.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

final class TooltipView: UIView {
    init(texts: [String]) {
        super.init(frame: .zero)
        setupView(texts: texts)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(texts: [String]) {
        backgroundColor = UIColor(red: 0.11, green: 0.15, blue: 0.24, alpha: 1)
        layer.cornerRadius = 16
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        for text in texts {
            let dot = UIView()
            dot.backgroundColor = .systemBlue
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8)
            ])
            
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = .white
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            
            let row = UIStackView(arrangedSubviews: [dot, label])
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .center
            
            stack.addArrangedSubview(row)
        }
        
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
}


final class CloudPaymentsLogoView: UIView {
    
    private let imageView = UIImageView()
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        imageView.image = UIImage.iconLogo
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}
