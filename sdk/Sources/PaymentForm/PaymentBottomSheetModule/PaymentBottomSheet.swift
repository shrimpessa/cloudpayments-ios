//
//  PaymentBottomSheetComponent.swift
//  sdk
//
//  Created by Cloudpayments on 20.05.2025.
//  Copyright © 2025 Cloudpayments. All rights reserved.
//

import UIKit

final class BottomSheetController: BaseViewController {
    
    // MARK: - Properties
    
    private let bottomSheetViewModel: BottomSheetViewModelProtocol
    private let contentVC: UIViewController
    
    private let containerView = UIView()
    private let dimmingView = UIView()
    
    private var containerBottomConstraint: NSLayoutConstraint?
    private var containerHeightConstraint: NSLayoutConstraint?
    
    private var panGesture: UIPanGestureRecognizer?
    
    private var isPerformingRotation = false
    
    var onDismiss: ((_ isSwipe: Bool) -> Void)?
    
    // MARK: - Init
    
    init(
        viewModel: BottomSheetViewModelProtocol,
        content: UIViewController
    ) {
        self.bottomSheetViewModel = viewModel
        self.contentVC = content
        
        super.init(
            nibName: nil,
            bundle: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Orientation
    
    override var shouldAutorotate: Bool {
        true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [
            .portrait,
            .landscapeLeft,
            .landscapeRight
        ]
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        setupDimming()
        setupContainer()
        layoutContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            
            self.view.layoutIfNeeded()
            self.contentVC.view.layoutIfNeeded()
            
            self.recalculateBottomSheetHeight(
                animated: false
            )
            
            self.animateIn()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard !isPerformingRotation else {
            return
        }
    }
    
    // MARK: - Rotation
    
    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(
            to: size,
            with: coordinator
        )
        
        isPerformingRotation = true
        
        coordinator.animate(
            alongsideTransition: { [weak self] _ in
                guard let self else {
                    return
                }
                
                self.view.layoutIfNeeded()
                self.contentVC.view.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                guard let self else {
                    return
                }
                
                self.isPerformingRotation = false
                
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                
                self.contentVC.view.setNeedsLayout()
                self.contentVC.view.layoutIfNeeded()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else {
                        return
                    }
                    
                    self.view.layoutIfNeeded()
                    self.contentVC.view.layoutIfNeeded()
                    
                    self.recalculateBottomSheetHeight(
                        animated: true
                    )
                }
            }
        )
    }
    
    // MARK: - Keyboard
    
    override func onKeyboardWillShow(
        _ notification: Notification
    ) {
        super.onKeyboardWillShow(
            notification
        )
        
        let availableHeight =
        view.bounds.height
        
        let keyboardHeight =
        min(
            keyboardFrame.height,
            availableHeight
        )
        
        containerBottomConstraint?.constant =
        -keyboardHeight
        
        UIView.animate(
            withDuration: 0.25
        ) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func onKeyboardWillHide(
        _ notification: Notification
    ) {
        super.onKeyboardWillHide(
            notification
        )
        
        containerBottomConstraint?.constant = 0
        
        UIView.animate(
            withDuration: 0.25
        ) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Setup Dimming
    
    private func setupDimming() {
        dimmingView.translatesAutoresizingMaskIntoConstraints =
        false
        
        dimmingView.backgroundColor =
        UIColor.black.withAlphaComponent(0.3)
        
        dimmingView.alpha = 0
        
        view.addSubview(
            dimmingView
        )
        
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            
            dimmingView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            
            dimmingView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            
            dimmingView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
        
        let tap =
        UITapGestureRecognizer(
            target: self,
            action: #selector(closeSheetFromTap)
        )
        
        dimmingView.addGestureRecognizer(
            tap
        )
    }
    
    // MARK: - Setup Container
    
    private func setupContainer() {
        containerView.backgroundColor =
            .white
        
        containerView.layer.cornerRadius =
        bottomSheetViewModel.cornerRadius
        
        containerView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        
        containerView.clipsToBounds = true
        
        containerView.translatesAutoresizingMaskIntoConstraints =
        false
        
        view.addSubview(
            containerView
        )
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            
            containerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            )
        ])
        
        let maxHeightConstraint =
        containerView.heightAnchor.constraint(
            lessThanOrEqualTo:
                view.safeAreaLayoutGuide.heightAnchor
        )
        
        maxHeightConstraint.priority = .required
        maxHeightConstraint.isActive = true
        
        // Bottom
        
        let bottomConstraint =
        containerView.bottomAnchor.constraint(
            equalTo: view.bottomAnchor
        )
        
        bottomConstraint.isActive = true
        
        containerBottomConstraint =
        bottomConstraint
        
        // Height
        
        let heightConstraint =
        containerView.heightAnchor.constraint(
            equalToConstant: 160
        )
        
        heightConstraint.priority =
            .required
        
        heightConstraint.isActive =
        true
        
        containerHeightConstraint =
        heightConstraint
        
        containerView.transform =
        CGAffineTransform(
            translationX: 0,
            y: UIScreen.main.bounds.height
        )
        
        // Pan
        
        let gesture =
        UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        
        gesture.delegate = self
        
        containerView.addGestureRecognizer(
            gesture
        )
        
        panGesture =
        gesture
    }
    
    // MARK: - Content
    
    private func layoutContent() {
        addChild(
            contentVC
        )
        
        containerView.addSubview(
            contentVC.view
        )
        
        contentVC.view.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            contentVC.view.topAnchor.constraint(
                equalTo: containerView.topAnchor
            ),
            
            contentVC.view.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor
            ),
            
            contentVC.view.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor
            ),
            
            contentVC.view.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor
            )
        ])
        
        contentVC.didMove(
            toParent: self
        )
        
        if let content =
            contentVC as? BottomSheetPaymentOptionsContentViewController {
            
            content.onContentChanged = { [weak self] in
                guard let self else {
                    return
                }
                
                guard !self.isPerformingRotation else {
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.recalculateBottomSheetHeight(
                        animated: true
                    )
                }
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.recalculateBottomSheetHeight(
                animated: false
            )
        }
    }
    
    // MARK: - Height
    
    private func recalculateBottomSheetHeight(
        animated: Bool
    ) {
        guard view.bounds.width > 0,
              view.bounds.height > 0 else {
            return
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        contentVC.view.setNeedsLayout()
        contentVC.view.layoutIfNeeded()
        
        let contentHeight =
        calculateContentHeight()
        let safeAreaHeight =
        view.safeAreaLayoutGuide.layoutFrame.height
        
        let landscape =
        view.bounds.width > view.bounds.height
        
        let maxHeight: CGFloat
        
        if landscape {
            maxHeight =
            safeAreaHeight
        } else {
            maxHeight =
            min(
                safeAreaHeight,
                view.bounds.height * 0.9
            )
        }
        
        let targetHeight =
        max(
            120,
            min(
                contentHeight,
                maxHeight
            )
        )
        
        containerHeightConstraint?.constant =
        targetHeight
        
        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [
                    .curveEaseInOut,
                    .beginFromCurrentState
                ]
            ) {
                self.view.layoutIfNeeded()
            }
            
        } else {
            view.layoutIfNeeded()
        }
    }
    
    private func calculateContentHeight() -> CGFloat {
        
        if let scrollView =
            findScrollView(
                in: contentVC.view
            ) {
            
            scrollView.setNeedsLayout()
            scrollView.layoutIfNeeded()
            
            let height =
            scrollView.contentSize.height
            
            if height > 0 {
                return height
            }
        }
        
        let width =
        containerView.bounds.width > 0
        ? containerView.bounds.width
        : view.bounds.width
        
        let targetSize =
        CGSize(
            width: width,
            height: UIView.layoutFittingCompressedSize.height
        )
        
        return contentVC.view.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }
    
    private func findScrollView(
        in view: UIView
    ) -> UIScrollView? {
        if let scrollView =
            view as? UIScrollView {
            return scrollView
        }
        
        for subview in view.subviews {
            if let scrollView =
                findScrollView(
                    in: subview
                ) {
                return scrollView
            }
        }
        
        return nil
    }
    
    // MARK: - Animation
    
    private func animateIn() {
        containerView.transform =
        CGAffineTransform(
            translationX: 0,
            y: view.bounds.height
        )
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0.05,
            options: [
                .curveEaseOut,
                .beginFromCurrentState
            ]
        ) {
            self.dimmingView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    // MARK: - Pan
    
    @objc private func handlePan(
        _ gesture: UIPanGestureRecognizer
    ) {
        let scrollView =
        findScrollView(
            in: contentVC.view
        )
        
        let translation =
        gesture.translation(
            in: view
        ).y
        
        let velocity =
        gesture.velocity(
            in: view
        ).y
        
        switch gesture.state {
            
        case .began:
            if let scrollView,
               scrollView.contentOffset.y <= 0,
               velocity > 0 {
                
                scrollView.isScrollEnabled =
                false
            }
            
        case .changed:
            if let scrollView {
                
                if scrollView.contentOffset.y <= 0,
                   translation > 0 {
                    
                    scrollView.contentOffset =
                        .zero
                    
                    containerView.transform =
                    CGAffineTransform(
                        translationX: 0,
                        y: max(
                            translation,
                            0
                        )
                    )
                    
                } else {
                    scrollView.isScrollEnabled =
                    true
                }
                
            } else {
                containerView.transform =
                CGAffineTransform(
                    translationX: 0,
                    y: max(
                        translation,
                        0
                    )
                )
            }
            
        case .ended,
                .cancelled:
            
            scrollView?.isScrollEnabled =
            true
            
            if containerView.transform.ty > 120 ||
                velocity > 1000 {
                
                closeSheet(
                    isSwipe: true
                )
                
            } else {
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [
                        .curveEaseOut,
                        .beginFromCurrentState
                    ]
                ) {
                    self.containerView.transform =
                        .identity
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Close
    
    @objc private func closeSheetFromTap() {
        closeSheet(
            isSwipe: false
        )
    }
    
    func closeSheetFromSwipe() {
        closeSheet(
            isSwipe: true
        )
    }
    
    @objc private func closeSheet(
        isSwipe: Bool
    ) {
        view.endEditing(
            true
        )
        
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [
                .curveEaseIn,
                .beginFromCurrentState
            ],
            animations: {
                self.dimmingView.alpha = 0
                
                self.containerView.transform =
                CGAffineTransform(
                    translationX: 0,
                    y: self.view.bounds.height
                )
            },
            completion: { _ in
                self.onDismiss?(
                    isSwipe
                )
                
                if self.presentingViewController != nil {
                    self.dismiss(
                        animated: false
                    )
                    
                } else {
                    self.willMove(
                        toParent: nil
                    )
                    
                    self.view.removeFromSuperview()
                    
                    self.removeFromParent()
                }
            }
        )
    }
    
    // MARK: - Present
    
    func present(
        in parent: UIViewController
    ) {
        parent.addChild(
            self
        )
        
        view.translatesAutoresizingMaskIntoConstraints =
        false
        
        parent.view.addSubview(
            view
        )
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(
                equalTo: parent.view.topAnchor
            ),
            
            view.leadingAnchor.constraint(
                equalTo: parent.view.leadingAnchor
            ),
            
            view.trailingAnchor.constraint(
                equalTo: parent.view.trailingAnchor
            ),
            
            view.bottomAnchor.constraint(
                equalTo: parent.view.bottomAnchor
            )
        ])
        
        parent.view.bringSubviewToFront(
            view
        )
        
        didMove(
            toParent: parent
        )
        
        parent.view.layoutIfNeeded()
    }
}

// MARK: - Gesture Delegate

extension BottomSheetController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        if touch.view is UITextField ||
            touch.view is UIControl {
            
            return false
        }
        
        return true
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
