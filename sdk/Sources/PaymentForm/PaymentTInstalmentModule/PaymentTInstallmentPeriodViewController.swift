//
//  PaymentTInstallmentPeriodViewController.swift
//  sdk
//
//  Created by Cloudpayments on 13.07.2026.
//  Copyright © 2026 Cloudpayments. All rights reserved.
//

import Foundation
import UIKit

final class PaymentTInstallmentPeriodViewController: BaseViewController {
    
    private let configuration: PaymentConfiguration
    private let useDimming: Bool
    private var pendingAutomaticPeriod: String?
    private var shouldOpenNextStepAutomatically = false
    private var didOpenNextStepAutomatically = false
    
    init(configuration: PaymentConfiguration, useDimming: Bool = true) {
        self.configuration = configuration
        self.useDimming = useDimming
        super.init(nibName: nil, bundle: .mainSdk)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = useDimming ? UIColor.black.withAlphaComponent(0.5) : .clear
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func present(
        with configuration: PaymentConfiguration,
        from presentingViewController: UIViewController
    ) {
        let controller = PaymentTInstallmentPeriodViewController(configuration: configuration)
        presentingViewController.present(controller, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showContent()
        LoggerService.shared.startLogging(publicId: configuration.publicId)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard shouldOpenNextStepAutomatically,
              !didOpenNextStepAutomatically else {
            return
        }
        
        didOpenNextStepAutomatically = true
        openNextStep(rawPeriod: pendingAutomaticPeriod)
    }
    
    private func showContent() {
        let periods = buildPeriodItems()
        if periods.count <= 1 {
            pendingAutomaticPeriod = periods.first?.rawValue
            shouldOpenNextStepAutomatically = true
            return
        }
        
        let defaultIndex = defaultSelectedIndex(for: periods.count)
        let selectedItem = periods[defaultIndex]
        
        let contentVC = PaymentTInstallmentPeriodContentViewController(
            periods: periods,
            selectedPeriod: selectedItem
        )
        
        contentVC.onContinueTapped = { [weak self] item in
            guard let self else { return }
            self.openNextStep(rawPeriod: item.rawValue)
        }
        
        let vm = BottomSheetViewModel(cornerRadius: 20)
        let sheet = BottomSheetController(
            viewModel: vm,
            content: contentVC
        )
        
        sheet.onDismiss = { [weak self] isSwipe in
            guard let self else { return }
                        
            guard isSwipe else {
                self.dismiss(animated: true)
                return
            }
            
            if self.configuration.singlePaymentMode == .tInstallment {
                self.dismiss(animated: true)
                return
            }
            
            guard let parent = self.presentingViewController else {
                self.dismiss(animated: true)
                return
            }
            
            self.dismiss(animated: false) {
                PaymentOptionsViewController.present(
                    with: self.configuration,
                    from: parent,
                    skipLoader: true
                )
                
                AnalyticsService.shared.sendPaymentMethodsScreenOpenedAgain(
                    configuration: self.configuration
                )
            }
        }
        
        sheet.present(in: self)
    }
    
    private func buildPeriodItems() -> [TInstallmentPeriodItem] {
        let rawPeriods = configuration.paymentData.periods
        
        return rawPeriods
            .compactMap { raw -> TInstallmentPeriodItem? in
                guard let months = Self.extractMonths(from: raw) else {
                    print("Не удалось распарсить период: \(raw)")
                    return nil
                }
                
                guard let amount = Double(configuration.paymentData.amount.replacingOccurrences(of: ",", with: ".")) else {
                    print("Не удалось преобразовать amount в Double: \(configuration.paymentData.amount)")
                    return nil
                }
                
                let payment = Self.monthlyPayment(amount: amount, months: months)
                let currencySign = Currency.getCurrencySign(code: configuration.paymentData.currency)
                let paymentText = "\(payment) \(currencySign)"
                
                return TInstallmentPeriodItem(
                    rawValue: raw,
                    months: months,
                    monthlyPaymentText: paymentText
                )
            }
            .sorted { $0.months < $1.months }
    }
    
    private func defaultSelectedIndex(for count: Int) -> Int {
        guard count > 1 else { return 0 }
        return (count - 1) / 2
    }
    
    private func openNextStep(rawPeriod: String?) {
        if let rawPeriod, !rawPeriod.isEmpty {
            configuration.paymentData.selectedTInstallmentPeriod = rawPeriod
            print("Сохранили выбранный period: \(rawPeriod)")
        } else {
            configuration.paymentData.selectedTInstallmentPeriod = nil
            print("Period отсутствует, продолжаем без period")
        }
        
        guard let parent = presentingViewController else {
            dismiss(animated: true)
            return
        }
        
        dismiss(animated: false) { [configuration] in
            ProgressTInstallmentViewController.present(
                with: configuration,
                from: parent
            )
        }
    }
    
    private static func extractMonths(from raw: String) -> Int? {
        let components = raw.split(separator: "_").map(String.init)
        guard components.count >= 4 else { return nil }
        return Int(components[3])
    }
    
    private static func monthlyPayment(amount: Double, months: Int) -> String {
        guard months > 0 else { return "0" }
        
        let rawValue = amount / Double(months)
        let scaled = rawValue * 100
        let rounded = scaled.rounded(.toNearestOrAwayFromZero) / 100
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = " "
        
        return formatter.string(from: NSNumber(value: rounded)) ?? "\(rounded)"
    }
}
