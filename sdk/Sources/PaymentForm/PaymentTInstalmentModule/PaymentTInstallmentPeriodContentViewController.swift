//
//  PaymentTInstallmentPeriodContentViewController.swift
//  sdk
//
//  Created by Cloudpayments on 13.07.2026.
//  Copyright © 2026 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

struct TInstallmentPeriodItem: Equatable {
    let rawValue: String
    let months: Int
    let monthlyPaymentText: String
}

final class PaymentTInstallmentPeriodContentViewController: BaseViewController {
    
    var onContinueTapped: ((TInstallmentPeriodItem) -> Void)?
    
    private let periods: [TInstallmentPeriodItem]
    private var selectedPeriod: TInstallmentPeriodItem
    
    private var currentIndex: Int {
        periods.firstIndex(of: selectedPeriod) ?? 0
    }
    
    private var activeTrackWidthConstraint: NSLayoutConstraint?
    private let infoBorderLayer = CAShapeLayer()
    private let borderColor = UIColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1)
    
    init(periods: [TInstallmentPeriodItem], selectedPeriod: TInstallmentPeriodItem) {
        self.periods = periods
        self.selectedPeriod = selectedPeriod
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Выберите срок рассрочки"
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let infoContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 0
        v.clipsToBounds = false
        return v
    }()
    
    private let periodTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Срок рассрочки"
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(red: 0.63, green: 0.63, blue: 0.67, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let paymentTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Платеж в месяц"
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(red: 0.63, green: 0.63, blue: 0.67, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let selectedPeriodLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let selectedPaymentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let trackBackgroundView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1)
        v.layer.cornerRadius = 0.5
        return v
    }()
    
    private let activeTrackView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.18, green: 0.45, blue: 0.99, alpha: 1)
        v.layer.cornerRadius = 0.5
        return v
    }()
    
    private let slider: UISlider = {
        let s = UISlider()
        s.minimumTrackTintColor = .clear
        s.maximumTrackTintColor = .clear
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private let minLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(red: 0.63, green: 0.63, blue: 0.67, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let maxLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(red: 0.63, green: 0.63, blue: 0.67, alpha: 1)
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .fixed
        config.background.cornerRadius = 12
        config.baseBackgroundColor = UIColor(red: 0.22, green: 0.45, blue: 0.95, alpha: 1)
        config.baseForegroundColor = .white
        config.title = "Далее"
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return button
    }()
    
    private let cpLogoView: CloudPaymentsLogoView = {
        let v = CloudPaymentsLogoView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        infoContainer.layer.addSublayer(infoBorderLayer)
        setupSlider()
        setupSliderAppearance()
        applySelectedPeriod()
        view.layoutIfNeeded()
        updateActiveTrack()
        updateInfoContainerBorder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateActiveTrack()
        updateInfoContainerBorder()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(handleView)
        view.addSubview(titleLabel)
        view.addSubview(infoContainer)
        
        view.addSubview(trackBackgroundView)
        view.addSubview(activeTrackView)
        view.addSubview(slider)
        
        view.addSubview(minLabel)
        view.addSubview(maxLabel)
        view.addSubview(continueButton)
        view.addSubview(cpLogoView)
        
        infoContainer.addSubview(periodTitleLabel)
        infoContainer.addSubview(paymentTitleLabel)
        infoContainer.addSubview(selectedPeriodLabel)
        infoContainer.addSubview(selectedPaymentLabel)
        
        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 136),
            handleView.heightAnchor.constraint(equalToConstant: 4),
            
            titleLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            infoContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            infoContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            infoContainer.heightAnchor.constraint(equalToConstant: 90),
            
            periodTitleLabel.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 18),
            periodTitleLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 18),
            
            paymentTitleLabel.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 18),
            paymentTitleLabel.leadingAnchor.constraint(equalTo: infoContainer.centerXAnchor, constant: 10),
            paymentTitleLabel.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -18),
            
            selectedPeriodLabel.topAnchor.constraint(equalTo: periodTitleLabel.bottomAnchor, constant: 6),
            selectedPeriodLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 18),
            
            selectedPaymentLabel.topAnchor.constraint(equalTo: paymentTitleLabel.bottomAnchor, constant: 6),
            selectedPaymentLabel.leadingAnchor.constraint(equalTo: infoContainer.centerXAnchor, constant: 10),
            selectedPaymentLabel.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -18),
            
            trackBackgroundView.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 22),
            trackBackgroundView.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -22),
            trackBackgroundView.centerYAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: 0),
            trackBackgroundView.heightAnchor.constraint(equalToConstant: 1),
            
            activeTrackView.leadingAnchor.constraint(equalTo: trackBackgroundView.leadingAnchor),
            activeTrackView.centerYAnchor.constraint(equalTo: trackBackgroundView.centerYAnchor),
            activeTrackView.heightAnchor.constraint(equalToConstant: 1),
            
            slider.leadingAnchor.constraint(equalTo: trackBackgroundView.leadingAnchor, constant: -2),
            slider.trailingAnchor.constraint(equalTo: trackBackgroundView.trailingAnchor, constant: 2),
            slider.centerYAnchor.constraint(equalTo: trackBackgroundView.centerYAnchor),
            
            minLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: -2),
            minLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            maxLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: -2),
            maxLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            continueButton.topAnchor.constraint(equalTo: minLabel.bottomAnchor, constant: 22),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            cpLogoView.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 20),
            cpLogoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cpLogoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        activeTrackWidthConstraint = activeTrackView.widthAnchor.constraint(equalToConstant: 0)
        activeTrackWidthConstraint?.isActive = true
        
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }
    
    private func setupSlider() {
        guard !periods.isEmpty else { return }
        
        slider.minimumValue = 0
        slider.maximumValue = Float(max(periods.count - 1, 0))
        slider.value = Float(currentIndex)
        
        minLabel.text = "\(periods.first?.months ?? 0) мес."
        maxLabel.text = "\(periods.last?.months ?? 0) мес."
        
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderDidEnd(_:)), for: [.touchUpInside, .touchUpOutside])
    }
    
    private func setupSliderAppearance() {
        let thumb = makeThumbImage()
        slider.setThumbImage(thumb, for: .normal)
        slider.setThumbImage(thumb, for: .highlighted)
        
        let clearTrack = makeClearTrackImage()
        slider.setMinimumTrackImage(clearTrack, for: .normal)
        slider.setMaximumTrackImage(clearTrack, for: .normal)
    }
    
    private func makeThumbImage() -> UIImage? {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(origin: .zero, size: size)
            
            let outerRect = rect.insetBy(dx: 1, dy: 1)
            cg.setFillColor(UIColor(red: 0.19, green: 0.42, blue: 0.95, alpha: 1).cgColor)
            cg.fillEllipse(in: outerRect)
            
            let innerRect = rect.insetBy(dx: 7, dy: 7)
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: innerRect)
        }
    }
    
    private func makeClearTrackImage() -> UIImage? {
        let size = CGSize(width: 4, height: 4)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { _ in
            UIColor.clear.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        }
        
        return image.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
    }
    
    private func updateActiveTrack() {
        let minValue = slider.minimumValue
        let maxValue = slider.maximumValue
        let value = slider.value
        
        guard maxValue > minValue else {
            activeTrackWidthConstraint?.constant = 0
            return
        }
        
        let progress = CGFloat((value - minValue) / (maxValue - minValue))
        let fullWidth = trackBackgroundView.bounds.width
        activeTrackWidthConstraint?.constant = fullWidth * progress
    }
    
    private func updateInfoContainerBorder() {
        let bounds = infoContainer.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        let radius: CGFloat = 16
        let cutInsetLeft: CGFloat = 22
        let cutInsetRight: CGFloat = 22
        
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: cutInsetLeft, y: bounds.height))
        path.addLine(to: CGPoint(x: radius, y: bounds.height))
        path.addArc(
            withCenter: CGPoint(x: radius, y: bounds.height - radius),
            radius: radius,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addArc(
            withCenter: CGPoint(x: radius, y: radius),
            radius: radius,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )
        
        path.addLine(to: CGPoint(x: bounds.width - radius, y: 0))
        path.addArc(
            withCenter: CGPoint(x: bounds.width - radius, y: radius),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height - radius))
        path.addArc(
            withCenter: CGPoint(x: bounds.width - radius, y: bounds.height - radius),
            radius: radius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        
        path.addLine(to: CGPoint(x: bounds.width - cutInsetRight, y: bounds.height))
        
        infoBorderLayer.frame = bounds
        infoBorderLayer.path = path.cgPath
        infoBorderLayer.fillColor = UIColor.clear.cgColor
        infoBorderLayer.strokeColor = borderColor.cgColor
        infoBorderLayer.lineWidth = 1
    }
    
    private func applySelectedPeriod() {
        selectedPeriodLabel.text = "\(selectedPeriod.months) \(monthsText(for: selectedPeriod.months))"
        selectedPaymentLabel.text = selectedPeriod.monthlyPaymentText
    }
    
    private func monthsText(for value: Int) -> String {
        let mod10 = value % 10
        let mod100 = value % 100
        
        if mod10 == 1 && mod100 != 11 {
            return "месяц"
        } else if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            return "месяца"
        } else {
            return "месяцев"
        }
    }
    
    @objc private func sliderChanged(_ sender: UISlider) {
        let index = Int(round(sender.value))
        sender.value = Float(index)
        
        guard periods.indices.contains(index) else { return }
        selectedPeriod = periods[index]
        applySelectedPeriod()
        updateActiveTrack()
    }
    
    @objc private func sliderDidEnd(_ sender: UISlider) {
        let index = Int(round(sender.value))
        sender.value = Float(index)
        
        guard periods.indices.contains(index) else { return }
        selectedPeriod = periods[index]
        applySelectedPeriod()
        updateActiveTrack()
    }
    
    @objc private func continueTapped() {
        onContinueTapped?(selectedPeriod)
    }
}
