//
//  PaymentResultViewController.swift
//  sdk
//
//  Created by Cloudpayments on 16.09.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit
import WebKit

protocol PaymentResultViewControllerDelegate: AnyObject {
    func paymentResultPrimaryTapped(
        state: PaymentResultViewController.State
    )
}

final class PaymentResultViewController: UIViewController {
    
    // MARK: - Public
    
    weak var delegate: PaymentResultViewControllerDelegate?
    
    private let state: State
    private let orderAlreadyBeenPaid: String?
    
    var onClose: (() -> Void)?
    
    // MARK: - State
    
    enum State {
        case completed(
            amountText: String?,
            transaction: PaymentTransactionResponse?
        )
        
        case declined(
            message: String?
        )
        
        var title: String {
            switch self {
            case .completed:
                return "Оплата прошла успешно"
                
            case .declined:
                return "Операция отклонена"
            }
        }
        
        var buttonTitle: String {
            switch self {
            case .completed:
                return "Вернуться в магазин"
                
            case .declined:
                return "Повторить попытку"
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .completed:
                return .iconSuccess
                
            case .declined:
                return .iconFailed
            }
        }
    }
    
    // MARK: - Present
    
    class func present(
        from parent: UIViewController,
        state: State,
        orderAlreadyBeenPaid: String? = nil,
        onClose: (() -> Void)? = nil
    ) {
        let vc =
        PaymentResultViewController(
            state: state,
            orderAlreadyBeenPaid: orderAlreadyBeenPaid,
            onClose: onClose
        )
        
        vc.modalPresentationStyle =
            .overFullScreen
        
        vc.modalTransitionStyle =
            .crossDissolve
        
        parent.present(
            vc,
            animated: true
        )
    }
    
    // MARK: - Init
    
    init(
        state: State,
        orderAlreadyBeenPaid: String? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.state = state
        self.onClose = onClose
        self.orderAlreadyBeenPaid = orderAlreadyBeenPaid
        
        super.init(
            nibName: nil,
            bundle: nil
        )
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    // MARK: - Orientation
    
    override var shouldAutorotate: Bool {
        true
    }
    
    override var supportedInterfaceOrientations:
    UIInterfaceOrientationMask {
        
        [
            .portrait,
            .landscapeLeft,
            .landscapeRight
        ]
    }
    
    // MARK: - UI
    
    private let dimView: UIView = {
        let view = UIView()
        
        view.backgroundColor =
        UIColor.black.withAlphaComponent(0.6)
        
        view.translatesAutoresizingMaskIntoConstraints =
        false
        
        return view
    }()
    
    private let container: UIView = {
        let view = UIView()
        
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        
        view.translatesAutoresizingMaskIntoConstraints =
        false
        
        return view
    }()
    
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.contentMode =
            .scaleAspectFit
        
        imageView.translatesAutoresizingMaskIntoConstraints =
        false
        
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        
        label.font =
            .systemFont(
                ofSize: 24,
                weight: .semibold
            )
        
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        
        label.translatesAutoresizingMaskIntoConstraints =
        false
        
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        
        label.font =
            .systemFont(
                ofSize: 16,
                weight: .regular
            )
        
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        
        label.translatesAutoresizingMaskIntoConstraints =
        false
        
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        
        label.font =
            .systemFont(
                ofSize: 16,
                weight: .regular
            )
        
        label.textColor =
            .secondaryLabel
        
        label.textAlignment =
            .center
        
        label.numberOfLines =
        0
        
        label.translatesAutoresizingMaskIntoConstraints =
        false
        
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        
        label.font =
            .systemFont(
                ofSize: 28,
                weight: .semibold
            )
        
        label.textColor = .label
        label.textAlignment = .center
        
        label.translatesAutoresizingMaskIntoConstraints =
        false
        
        return label
    }()
    
    private let actionButton: UIButton = {
        var config =
        UIButton.Configuration.filled()
        
        config.cornerStyle =
            .fixed
        
        config.background.cornerRadius =
        12
        
        config.contentInsets =
            .init(
                top: 14,
                leading: 16,
                bottom: 14,
                trailing: 16
            )
        
        let button =
        UIButton(
            configuration: config
        )
        
        button.translatesAutoresizingMaskIntoConstraints =
        false
        
        return button
    }()
    
    private let cpLogoView: CloudPaymentsLogoView = {
        let view =
        CloudPaymentsLogoView()
        
        view.translatesAutoresizingMaskIntoConstraints =
        false
        
        return view
    }()
    
    // MARK: - Constraints
    
    private var containerLeadingConstraint: NSLayoutConstraint!
    private var containerTrailingConstraint: NSLayoutConstraint!
    
    private var iconTopConstraint: NSLayoutConstraint!
    private var iconHeightConstraint: NSLayoutConstraint!
    private var iconWidthConstraint: NSLayoutConstraint!
    
    private var titleTopConstraint: NSLayoutConstraint!
    
    private var logoTopConstraint: NSLayoutConstraint!
    private var logoBottomConstraint: NSLayoutConstraint!
    
    private var titleToAmountConstraint: NSLayoutConstraint!
    private var titleToMessageConstraint: NSLayoutConstraint!
    
    private var buttonToAmountConstraint: NSLayoutConstraint!
    private var buttonToMessageConstraint: NSLayoutConstraint!
    private var buttonToSubtitleConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        apply(state)
        
        updateLayoutForSize(
            view.bounds.size
        )
    }
    
    override func viewWillTransition(
        to size: CGSize,
        with coordinator:
        UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(
            to: size,
            with: coordinator
        )
        
        coordinator.animate(
            alongsideTransition: {
                [weak self] _ in
                
                guard let self else {
                    return
                }
                
                self.updateLayoutForSize(
                    size
                )
                
                self.view.layoutIfNeeded()
            }
        )
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(
            dimView
        )
        
        view.addSubview(
            container
        )
        
        containerLeadingConstraint =
        container.leadingAnchor.constraint(
            equalTo:
                view.safeAreaLayoutGuide.leadingAnchor,
            constant: 16
        )
        
        containerTrailingConstraint =
        container.trailingAnchor.constraint(
            equalTo:
                view.safeAreaLayoutGuide.trailingAnchor,
            constant: -16
        )
        
        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            
            dimView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            
            dimView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            
            dimView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            
            containerLeadingConstraint,
            containerTrailingConstraint,
            
            container.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            
            container.topAnchor.constraint(
                greaterThanOrEqualTo:
                    view.safeAreaLayoutGuide.topAnchor,
                constant: 8
            ),
            
            container.bottomAnchor.constraint(
                lessThanOrEqualTo:
                    view.safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            )
        ])
        
        // MARK: Container subviews
        
        container.addSubview(
            iconView
        )
        
        container.addSubview(
            titleLabel
        )
        
        container.addSubview(
            subtitleLabel
        )
        
        container.addSubview(
            messageLabel
        )
        
        container.addSubview(
            amountLabel
        )
        
        container.addSubview(
            actionButton
        )
        
        container.addSubview(
            cpLogoView
        )
        
        // MARK: Icon
        
        iconTopConstraint =
        iconView.topAnchor.constraint(
            equalTo: container.topAnchor,
            constant: 20
        )
        
        iconHeightConstraint =
        iconView.heightAnchor.constraint(
            equalToConstant: 180
        )
        
        iconWidthConstraint =
        iconView.widthAnchor.constraint(
            equalToConstant: 180
        )
        
        NSLayoutConstraint.activate([
            iconTopConstraint,
            
            iconView.centerXAnchor.constraint(
                equalTo:
                    container.centerXAnchor
            ),
            
            iconHeightConstraint,
            iconWidthConstraint
        ])
        
        // MARK: Title
        
        titleTopConstraint =
        titleLabel.topAnchor.constraint(
            equalTo:
                iconView.bottomAnchor,
            constant: 40
        )
        
        NSLayoutConstraint.activate([
            titleTopConstraint,
            
            titleLabel.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor,
                constant: 24
            ),
            
            titleLabel.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor,
                constant: -24
            )
        ])
        
        // MARK: Subtitle
        
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(
                equalTo:
                    titleLabel.bottomAnchor,
                constant: 8
            ),
            
            subtitleLabel.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor,
                constant: 24
            ),
            
            subtitleLabel.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor,
                constant: -24
            )
        ])
        
        // MARK: Amount
        
        NSLayoutConstraint.activate([
            amountLabel.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor,
                constant: 24
            ),
            
            amountLabel.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor,
                constant: -24
            )
        ])
        
        titleToAmountConstraint =
        amountLabel.topAnchor.constraint(
            equalTo:
                subtitleLabel.bottomAnchor,
            constant: 20
        )
        
        // MARK: Message
        
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor,
                constant: 24
            ),
            
            messageLabel.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor,
                constant: -24
            )
        ])
        
        titleToMessageConstraint =
        messageLabel.topAnchor.constraint(
            equalTo:
                subtitleLabel.bottomAnchor,
            constant: 10
        )
        
        // MARK: Button
        
        buttonToAmountConstraint =
        actionButton.topAnchor.constraint(
            equalTo:
                amountLabel.bottomAnchor,
            constant: 40
        )
        
        buttonToMessageConstraint =
        actionButton.topAnchor.constraint(
            equalTo:
                messageLabel.bottomAnchor,
            constant: 40
        )
        
        buttonToSubtitleConstraint =
        actionButton.topAnchor.constraint(
            equalTo:
                subtitleLabel.bottomAnchor,
            constant: 40
        )
        
        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor,
                constant: 24
            ),
            
            actionButton.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor,
                constant: -24
            ),
            
            actionButton.heightAnchor.constraint(
                equalToConstant: 56
            )
        ])
        
        // MARK: Logo
        
        logoTopConstraint =
        cpLogoView.topAnchor.constraint(
            equalTo:
                actionButton.bottomAnchor,
            constant: 40
        )
        
        logoBottomConstraint =
        cpLogoView.bottomAnchor.constraint(
            equalTo:
                container.bottomAnchor,
            constant: -20
        )
        
        NSLayoutConstraint.activate([
            logoTopConstraint,
            
            cpLogoView.centerXAnchor.constraint(
                equalTo:
                    container.centerXAnchor
            ),
            
            cpLogoView.heightAnchor.constraint(
                equalToConstant: 24
            ),
            
            cpLogoView.widthAnchor.constraint(
                greaterThanOrEqualToConstant: 120
            ),
            
            logoBottomConstraint
        ])
        
        actionButton.addTarget(
            self,
            action:
                #selector(primaryTapped),
            for:
                    .touchUpInside
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
            containerLeadingConstraint.constant = 80
            containerTrailingConstraint.constant = -80
            
            iconTopConstraint.constant = 10
            iconHeightConstraint.constant = 76
            iconWidthConstraint.constant = 76
            
            titleTopConstraint.constant = 8
            
            titleLabel.font =
                .systemFont(
                    ofSize: 20,
                    weight: .semibold
                )
            
            subtitleLabel.font =
                .systemFont(
                    ofSize: 14,
                    weight: .regular
                )
            
            messageLabel.font =
                .systemFont(
                    ofSize: 14,
                    weight: .regular
                )
            
            amountLabel.font =
                .systemFont(
                    ofSize: 22,
                    weight: .semibold
                )
            
            buttonToAmountConstraint.constant = 14
            buttonToMessageConstraint.constant = 14
            buttonToSubtitleConstraint.constant = 14
            
            logoTopConstraint.constant = 10
            logoBottomConstraint.constant = -10
            
        } else {
            containerLeadingConstraint.constant = 16
            containerTrailingConstraint.constant = -16
            
            iconTopConstraint.constant = 20
            iconHeightConstraint.constant = 180
            iconWidthConstraint.constant = 180
            
            titleTopConstraint.constant = 40
            
            titleLabel.font =
                .systemFont(
                    ofSize: 24,
                    weight: .semibold
                )
            
            subtitleLabel.font =
                .systemFont(
                    ofSize: 16,
                    weight: .regular
                )
            
            messageLabel.font =
                .systemFont(
                    ofSize: 16,
                    weight: .regular
                )
            
            amountLabel.font =
                .systemFont(
                    ofSize: 28,
                    weight: .semibold
                )
            
            buttonToAmountConstraint.constant = 40
            buttonToMessageConstraint.constant = 40
            buttonToSubtitleConstraint.constant = 40
            
            logoTopConstraint.constant = 40
            logoBottomConstraint.constant = -20
        }
    }
    
    // MARK: - Data -> UI
    
    private func apply(
        _ state: State
    ) {
        iconView.image =
        state.icon
        
        titleLabel.text =
        state.title
        
        actionButton.configuration?.title =
        state.buttonTitle
        
        amountLabel.isHidden = true
        messageLabel.isHidden = true
        subtitleLabel.isHidden = true
        
        titleToAmountConstraint.isActive = false
        titleToMessageConstraint.isActive = false
        
        buttonToAmountConstraint.isActive = false
        buttonToMessageConstraint.isActive = false
        buttonToSubtitleConstraint.isActive = false
        
        switch state {
            
        case .completed(
            let amountText,
            _
        ):
            
            if orderAlreadyBeenPaid ==
                .orderAlreadyBeenPaid {
                
                titleLabel.text =
                orderAlreadyBeenPaid
                
            } else {
                titleLabel.text =
                state.title
            }
            
            subtitleLabel.text =
                .orderPaid
            
            subtitleLabel.isHidden =
            false
            
            let hasAmount: Bool = {
                guard let amountText else {
                    return false
                }
                
                return !amountText.isEmpty
            }()
            
            if hasAmount {
                amountLabel.text =
                amountText
                
                amountLabel.isHidden =
                false
                
                titleToAmountConstraint.isActive =
                true
                
                buttonToAmountConstraint.isActive =
                true
                
            } else {
                buttonToSubtitleConstraint.isActive =
                true
            }
            
        case .declined(
            let message
        ):
            
            let text: String
            
            if let message,
               !message.isEmpty {
                
                if message.contains("#") {
                    text =
                    message
                        .components(
                            separatedBy: "#"
                        )
                        .joined(
                            separator: "\n"
                        )
                } else {
                    text = message
                }
                
            } else {
                text =
                    .errorDescription
            }
            
            messageLabel.text =
            text
            
            messageLabel.isHidden =
            false
            
            titleToMessageConstraint.isActive =
            true
            
            buttonToMessageConstraint.isActive =
            true
        }
    }
    
    // MARK: - Actions
    
    @objc private func primaryTapped() {
        dismiss(
            animated: true
        ) {
            self.delegate?
                .paymentResultPrimaryTapped(
                    state: self.state
                )
            
            self.onClose?()
        }
    }
}
