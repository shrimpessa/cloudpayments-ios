//
//  ProgressPaymentView.swift
//  sdk
//
//  Created by Cloudpayments on 29.07.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//


import UIKit
import Foundation

protocol ProgressPaymentViewDelegate: AnyObject {
    func closePaymentButton()
}

final class ProgressPaymentView: UIView {
    
    weak var delegate: ProgressPaymentViewDelegate?
    
    private let method: PaymentMethodType
    private let useDimming: Bool
    
    // MARK: - Subviews
    
    private lazy var contentView = UIView(
        backgroundColor: .whiteColor,
        cornerRadius: Constants.Radius.medium
    )
    
    private lazy var alertImageView = UIImageView(
        image: .iconProgress,
        contentMode: .scaleAspectFit
    )
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = method.titleText
        label.textColor = .mainText
        label.font = .boldSystemFont(ofSize: Constants.Font.bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var methodLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = method.methodLogoImage
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleContainerView: UIStackView = {
        var arrangedViews: [UIView] = [titleLabel]
        
        if let logo = method.methodLogoImage {
            methodLogoImageView.image = logo
            
            let logoSize: CGSize
            
            switch method {
            case .dolyame:
                logoSize = CGSize(
                    width: 100,
                    height: 20
                )
                
            default:
                logoSize = CGSize(
                    width: 63,
                    height: 30
                )
            }
            
            NSLayoutConstraint.activate([
                methodLogoImageView.widthAnchor.constraint(
                    equalToConstant: logoSize.width
                ),
                
                methodLogoImageView.heightAnchor.constraint(
                    equalToConstant: logoSize.height
                )
            ])
            
            arrangedViews.append(
                methodLogoImageView
            )
        }
        
        let stack = UIStackView(
            arrangedSubviews: arrangedViews
        )
        
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        return stack
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = .failedPay
        label.textColor = .colorProgressText
        label.font = .systemFont(ofSize: Constants.Font.regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var button = UIButton(
        .colorBlue,
        8,
        1,
        .paymentMethod,
        .colorBlue
    )
    
    private lazy var logoImageView = CloudPaymentsLogoView()
    
    // MARK: - Adaptive Constraints
    
    private var contentLeadingConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!
    
    private var alertTopConstraint: NSLayoutConstraint!
    private var alertHeightConstraint: NSLayoutConstraint!
    
    private var centerTopConstraint: NSLayoutConstraint!
    private var footerTopConstraint: NSLayoutConstraint!
    
    private var buttonHeightConstraint: NSLayoutConstraint!
    private var buttonTopConstraint: NSLayoutConstraint!
    
    private var logoBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Init
    
    init(
        method: PaymentMethodType,
        useDimming: Bool = false
    ) {
        self.method = method
        self.useDimming = useDimming
        
        super.init(frame: .zero)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateLayoutForSize(
            bounds.size
        )
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = useDimming
        ? UIColor.black.withAlphaComponent(0.5)
        : .clear
        
        let textView = UIView()
        let buttonView = UIView()
        let logoView = UIView()
        
        [
            textView,
            buttonView,
            logoView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        logoView.addSubview(
            logoImageView
        )
        
        if method != .card {
            textView.addSubview(
                descriptionLabel
            )
        }
        
        if method != .card {
            buttonView.addSubview(
                button
            )
            
            button.addTarget(
                self,
                action: #selector(closeController),
                for: .touchUpInside
            )
        }
        
        let centerStackView = UIStackView(
            arrangedSubviews: [
                titleContainerView,
                textView
            ]
        )
        
        centerStackView.axis = .vertical
        centerStackView.alignment = .center
        centerStackView.spacing = method == .card ? 0 : 10
        centerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let footerArranged: [UIView] =
        method == .card
        ? [logoView]
        : [buttonView, logoView]
        
        let footerStackView = UIStackView(
            arrangedSubviews: footerArranged
        )
        
        footerStackView.axis = .vertical
        footerStackView.spacing = 12
        footerStackView.alignment = .fill
        footerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubviews(
            alertImageView,
            centerStackView,
            footerStackView
        )
        
        addSubview(
            contentView
        )
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        alertImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // MARK: Content
        
        contentLeadingConstraint =
        contentView.leadingAnchor.constraint(
            equalTo: safeAreaLayoutGuide.leadingAnchor,
            constant: Constants.ContentView.leadingAnchor
        )
        
        contentTrailingConstraint =
        contentView.trailingAnchor.constraint(
            equalTo: safeAreaLayoutGuide.trailingAnchor,
            constant: Constants.ContentView.trailingAnchor
        )
        
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(
                equalTo: safeAreaLayoutGuide.centerXAnchor
            ),
            
            contentView.centerYAnchor.constraint(
                equalTo: safeAreaLayoutGuide.centerYAnchor
            ),
            
            contentLeadingConstraint,
            contentTrailingConstraint,
            
            contentView.topAnchor.constraint(
                greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor,
                constant: 8
            ),
            
            contentView.bottomAnchor.constraint(
                lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            )
        ])
        
        // MARK: Alert
        
        alertTopConstraint =
        alertImageView.topAnchor.constraint(
            equalTo: contentView.topAnchor,
            constant: Constants.AlertImageView.topAnchor
        )
        
        alertHeightConstraint =
        alertImageView.heightAnchor.constraint(
            equalToConstant: Constants.AlertImageView.heightAnchor
        )
        
        NSLayoutConstraint.activate([
            alertTopConstraint,
            
            alertImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Constants.AlertImageView.leadingAnchor
            ),
            
            alertImageView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: Constants.AlertImageView.trailingAnchor
            ),
            
            alertHeightConstraint
        ])
        
        // MARK: Center stack
        
        centerTopConstraint =
        centerStackView.topAnchor.constraint(
            equalTo: alertImageView.bottomAnchor,
            constant: Constants.CenterStackView.topAnchor
        )
        
        NSLayoutConstraint.activate([
            centerTopConstraint,
            
            centerStackView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Constants.CenterStackView.leadingAnchor
            ),
            
            centerStackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: Constants.CenterStackView.trailingAnchor
            )
        ])
        
        // MARK: Footer
        
        footerTopConstraint =
        footerStackView.topAnchor.constraint(
            equalTo: centerStackView.bottomAnchor,
            constant: 20
        )
        
        NSLayoutConstraint.activate([
            footerTopConstraint,
            
            footerStackView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Constants.FooterStackView.leadingAnchor
            ),
            
            footerStackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: Constants.FooterStackView.trailingAnchor
            ),
            
            footerStackView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: Constants.FooterStackView.bottomAnchor
            )
        ])
        
        // MARK: Logo
        
        logoBottomConstraint =
        logoImageView.bottomAnchor.constraint(
            equalTo: logoView.bottomAnchor,
            constant: -20
        )
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(
                equalTo: logoView.centerXAnchor
            ),
            
            logoImageView.centerYAnchor.constraint(
                equalTo: logoView.centerYAnchor
            ),
            
            logoBottomConstraint
        ])
        
        // MARK: Method != card
        
        if method != .card {
            NSLayoutConstraint.activate([
                descriptionLabel.topAnchor.constraint(
                    equalTo: textView.topAnchor
                ),
                
                descriptionLabel.leadingAnchor.constraint(
                    equalTo: textView.leadingAnchor
                ),
                
                descriptionLabel.trailingAnchor.constraint(
                    equalTo: textView.trailingAnchor
                ),
                
                descriptionLabel.bottomAnchor.constraint(
                    equalTo: textView.bottomAnchor
                )
            ])
            
            buttonTopConstraint =
            button.topAnchor.constraint(
                equalTo: buttonView.topAnchor,
                constant: Constants.Button.topAnchor
            )
            
            buttonHeightConstraint =
            button.heightAnchor.constraint(
                equalToConstant: Constants.Button.heightAnchor
            )
            
            NSLayoutConstraint.activate([
                buttonTopConstraint,
                
                button.leadingAnchor.constraint(
                    equalTo: buttonView.leadingAnchor
                ),
                
                button.trailingAnchor.constraint(
                    equalTo: buttonView.trailingAnchor
                ),
                
                button.bottomAnchor.constraint(
                    equalTo: buttonView.bottomAnchor
                ),
                
                buttonHeightConstraint
            ])
        }
        
        updateLayoutForSize(
            bounds.size
        )
    }
    
    // MARK: - Adaptive Layout
    
    private func updateLayoutForSize(
        _ size: CGSize
    ) {
        guard size.width > 0,
              size.height > 0 else {
            return
        }
        
        let isLandscape =
        size.width > size.height
        
        if isLandscape {
            contentLeadingConstraint.constant = 80
            contentTrailingConstraint.constant = -80
            
            alertTopConstraint.constant = 12
            alertHeightConstraint.constant = 80
            
            centerTopConstraint.constant = 10
            footerTopConstraint.constant = 12
            
            buttonTopConstraint?.constant = 8
            buttonHeightConstraint?.constant = 48
            
            logoBottomConstraint.constant = -10
            
            titleLabel.font =
                .boldSystemFont(
                    ofSize: 18
                )
            
            descriptionLabel.font =
                .systemFont(
                    ofSize: 14
                )
            
        } else {
            contentLeadingConstraint.constant =
            Constants.ContentView.leadingAnchor
            
            contentTrailingConstraint.constant =
            Constants.ContentView.trailingAnchor
            
            alertTopConstraint.constant =
            Constants.AlertImageView.topAnchor
            
            alertHeightConstraint.constant =
            Constants.AlertImageView.heightAnchor
            
            centerTopConstraint.constant =
            Constants.CenterStackView.topAnchor
            
            footerTopConstraint.constant = 20
            
            buttonTopConstraint?.constant =
            Constants.Button.topAnchor
            
            buttonHeightConstraint?.constant =
            Constants.Button.heightAnchor
            
            logoBottomConstraint.constant = -20
            
            titleLabel.font =
                .boldSystemFont(
                    ofSize: Constants.Font.bold
                )
            
            descriptionLabel.font =
                .systemFont(
                    ofSize: Constants.Font.regular
                )
        }
    }
    
    // MARK: - Action
    
    @objc private func closeController() {
        delegate?
            .closePaymentButton()
    }
}


// MARK: - Constants

private enum Constants {
    
    enum ContentView {
        static let leadingAnchor: CGFloat = 16
        static let trailingAnchor: CGFloat = -16
    }
    
    enum AlertImageView {
        static let topAnchor: CGFloat = 20
        static let leadingAnchor: CGFloat = 20
        static let trailingAnchor: CGFloat = -20
        static let heightAnchor: CGFloat = 180
    }
    
    enum CenterStackView {
        static let topAnchor: CGFloat = 20
        static let leadingAnchor: CGFloat = 20
        static let trailingAnchor: CGFloat = -20
    }
    
    enum FooterStackView {
        static let leadingAnchor: CGFloat = 20
        static let trailingAnchor: CGFloat = -20
        static let bottomAnchor: CGFloat = -12
    }
    
    enum Button {
        static let topAnchor: CGFloat = 20
        static let heightAnchor: CGFloat = 56
    }
    
    enum LogoImageView {
        static let heightAnchor: CGFloat = 18
    }
    
    enum Font {
        static let bold: CGFloat = 20
        static let regular: CGFloat = 15
    }
    
    enum Radius {
        static let medium: CGFloat = 14
    }
}
