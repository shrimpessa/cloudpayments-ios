//
//  DemoController.swift
//  demo
//
//  Created by Cloudpayments on 23.06.2026.
//  Copyright © 2026 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation
import Cloudpayments

final class DemoController: BaseViewController {

    // MARK: - Private properties

    private let tableView = UITableView(
        frame: .zero,
        style: .plain
    )

    private var viewModels = PaymentViewModel.getViewModel()

    private let footer = FooterActionView()

    private let footerHeight: CGFloat = 420

    // MARK: - LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupNavigationButtons()
        setupFooter()
        setupTableView()
        setupGesture()
    }

    // MARK: - Private methods

    private func setupView() {
        title = "Cloudpayments SDK Demo"
        view.backgroundColor = .white
    }

    private func setupNavigationButtons() {
        let buttonSize: CGFloat = 32
        let spacing: CGFloat = 4

        let containerWidth = buttonSize * 3 + spacing * 2

        let containerView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: containerWidth,
                height: buttonSize
            )
        )

        let resetButton = UIButton(
            type: .system
        )

        resetButton.frame = CGRect(
            x: 0,
            y: 0,
            width: buttonSize,
            height: buttonSize
        )

        resetButton.setImage(
            UIImage(systemName: "arrow.clockwise"),
            for: .normal
        )

        resetButton.addTarget(
            self,
            action: #selector(resetConfiguration),
            for: .touchUpInside
        )

        let loadButton = UIButton(
            type: .system
        )

        loadButton.frame = CGRect(
            x: buttonSize + spacing,
            y: 0,
            width: buttonSize,
            height: buttonSize
        )

        loadButton.setImage(
            UIImage(systemName: "folder"),
            for: .normal
        )

        loadButton.addTarget(
            self,
            action: #selector(showSavedConfigurations),
            for: .touchUpInside
        )

        let saveButton = UIButton(
            type: .system
        )

        saveButton.frame = CGRect(
            x: (buttonSize + spacing) * 2,
            y: 0,
            width: buttonSize,
            height: buttonSize
        )

        saveButton.setImage(
            UIImage(systemName: "externaldrive.fill"),
            for: .normal
        )

        saveButton.addTarget(
            self,
            action: #selector(showSaveConfigurationAlert),
            for: .touchUpInside
        )

        containerView.addSubview(resetButton)
        containerView.addSubview(loadButton)
        containerView.addSubview(saveButton)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            customView: containerView
        )
    }

    private func setupFooter() {
        view.addSubview(footer)

        footer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            footer.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            footer.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),
            footer.heightAnchor.constraint(
                equalToConstant: footerHeight
            )
        ])

        footer.addTarget(
            target: self,
            action: #selector(run(_:)),
            .demo
        )
    }

    private func setupTableView() {
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            tableView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            tableView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            tableView.bottomAnchor.constraint(
                equalTo: footer.topAnchor
            )
        ])

        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive

        tableView.contentInset = UIEdgeInsets(
            top: 8,
            left: 0,
            bottom: 16,
            right: 0
        )

        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(
            DemoViewCell.self,
            forCellReuseIdentifier: DemoViewCell.reuseIdentifier
        )

        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(tapAction)
        )

        tap.cancelsTouchesInView = false

        view.addGestureRecognizer(tap)
    }

    @objc private func tapAction() {
        view.endEditing(true)
    }

    private func getText(
        _ type: PaymentViewModelType
    ) -> String? {
        for value in viewModels {
            if value.type == type {
                return value.text
            }
        }

        return nil
    }

    private func saveCurrentState() {
        view.endEditing(true)

        PaymentViewModel.saving(viewModels)
    }

    private func applyConfiguration(
        _ configuration: SavedPaymentConfiguration
    ) {
        view.endEditing(true)

        viewModels = configuration.fields

        footer.setState(
            isDualMessagePaymentEnabled:
                configuration.isDualMessagePaymentEnabled,
            isRecurrentEnabled:
                configuration.isRecurrentEnabled,
            isReceiptEnabled:
                configuration.isReceiptEnabled
        )

        PaymentViewModel.saving(viewModels)

        tableView.reloadData()

        print(
            "Загружена конфигурация: \(configuration.name)"
        )
    }

    private func showMessage(
        title: String,
        message: String? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Закрыть",
                style: .default
            )
        )

        present(
            alert,
            animated: true
        )
    }

    // MARK: - Reset configuration

    @objc private func resetConfiguration() {
        view.endEditing(true)

        let alert = UIAlertController(
            title: "Сбросить конфигурацию?",
            message: "Все поля и переключатели вернутся к значениям по умолчанию.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Отмена",
                style: .cancel
            )
        )

        alert.addAction(
            UIAlertAction(
                title: "Сбросить",
                style: .destructive,
                handler: { [weak self] _ in
                    guard let self else {
                        return
                    }

                    self.viewModels =
                        PaymentViewModel.defaultViewModels()

                    self.footer.resetState()

                    PaymentViewModel.resetCurrentConfiguration()
                    PaymentViewModel.saving(self.viewModels)

                    self.tableView.reloadData()
                    self.tableView.setContentOffset(
                        .zero,
                        animated: true
                    )

                    print(
                        "Текущая конфигурация сброшена"
                    )
                }
            )
        )

        present(
            alert,
            animated: true
        )
    }

    // MARK: - Save configuration

    @objc private func showSaveConfigurationAlert() {
        saveCurrentState()

        let alert = UIAlertController(
            title: "Сохранить конфигурацию",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Название"
            textField.clearButtonMode = .whileEditing
            textField.autocapitalizationType = .sentences
        }

        let cancelAction = UIAlertAction(
            title: "Отмена",
            style: .cancel
        )

        let saveAction = UIAlertAction(
            title: "Сохранить",
            style: .default,
            handler: { [weak self, weak alert] _ in
                guard
                    let self,
                    let name = alert?
                        .textFields?
                        .first?
                        .text?
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),
                    !name.isEmpty
                else {
                    return
                }

                let configuration =
                    SavedPaymentConfiguration(
                        name: name,
                        fields: self.viewModels,
                        isDualMessagePaymentEnabled:
                            self.footer
                                .isDualMessagePaymentEnabled,
                        isRecurrentEnabled:
                            self.footer.isRecurrentEnabled,
                        isReceiptEnabled:
                            self.footer.isReceiptEnabled
                    )

                SavedPaymentConfigurationStorage
                    .shared
                    .saveConfiguration(configuration)

                self.showMessage(
                    title: "Конфигурация сохранена",
                    message: name
                )
            }
        )

        saveAction.isEnabled = false

        alert.addAction(cancelAction)
        alert.addAction(saveAction)

        if let textField = alert.textFields?.first {
            NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { [weak textField, weak saveAction] _ in
                let name = textField?
                    .text?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

                saveAction?.isEnabled = !name.isEmpty
            }
        }

        present(
            alert,
            animated: true
        )
    }

    // MARK: - Load configuration

    @objc private func showSavedConfigurations() {
        view.endEditing(true)

        let configurations =
            SavedPaymentConfigurationStorage
                .shared
                .getConfigurations()

        guard !configurations.isEmpty else {
            showMessage(
                title: "Нет сохранённых конфигураций",
                message: "Сначала сохраните текущую конфигурацию."
            )

            return
        }

        let controller =
            SavedConfigurationsViewController()

        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve

        controller.onConfigurationSelected = {
            [weak self] configuration in

            self?.applyConfiguration(configuration)
        }

        present(
            controller,
            animated: true
        )
    }

    // MARK: - Standard Form

    @objc private func run(_ sender: UIButton) {
        saveCurrentState()

        guard
            let publicId = getText(.publicId),
            let amount = getText(.amount),
            let currency = getText(.currency),
            let invoiceId = getText(.invoiceId),
            let descript = getText(.description),
            let account = getText(.accountId),
            let email = getText(.email),
            let jsonData = getText(.jsonData)
        else {
            return
        }

        let receipt: [String: Any] = [
            "Items": [
                [
                    "label": "Товар",
                    "price": 1.95,
                    "quantity": 1,
                    "amount": 1.95,
                    "vat": 0,
                    "method": 4,
                    "object": 1
                ]
            ],
            "taxationSystem": 0,
            "email": "test@test.ru",
            "amounts": [
                "electronic": 1.95,
                "advancePayment": 0,
                "credit": 0,
                "provision": 0
            ]
        ]

        let recurrent = Recurrent(
            interval: "Week",
            period: 1,
            receipt: receipt,
            amount: 730.65
        )

//        let payer = PaymentDataPayer(
//            firstName: payerFirstName,
//            lastName: payerLastName,
//            middleName: payerMiddleName,
//            birth: payerBirthday,
//            address: payerAddress,
//            street: payerStreet,
//            city: payerCity,
//            country: payerCountry,
//            phone: payerPhone,
//            postcode: payerPostcode
//        )

        var paymentData = PaymentData()
            .setAmount(amount)
            .setCurrency(currency)
            .setCardholderName("CP SDK")
            .setInvoiceId(invoiceId)
            .setDescription(descript)
            .setAccountId(account)
//            .setPayer(payer)
            .setEmail(email)
            .setJsonData(jsonData)

        if footer.isReceiptEnabled {
            paymentData = paymentData.setReceipt(receipt)
        }

        if footer.isRecurrentEnabled {
            paymentData = paymentData.setRecurrent(recurrent)
        }

        let configuration = PaymentConfiguration(
            publicId: publicId,
            paymentData: paymentData,
            delegate: self,
            uiDelegate: self,
            emailBehavior: .optional,
            paymentMethodSequence: [],
            // singlePaymentMode: .tpay,
            useDualMessagePayment:
                footer.isDualMessagePaymentEnabled,
            showResultScreenForSinglePaymentMode: true
            // successRedirectUrl: "https://ya.ru",
            // failRedirectUrl: "https://ya.ru",
        )

        PaymentOptionsViewController.present(
            with: configuration,
            from: self
        )
    }
}


extension DemoController:
    UITableViewDelegate,
    UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return viewModels.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DemoViewCell.reuseIdentifier,
                for: indexPath
            ) as? DemoViewCell
        else {
            return UITableViewCell()
        }

        let value = viewModels[indexPath.row]

        cell.setupView(viewModel: value)

        cell.addTarget(
            self,
            action: #selector(textFieldEditing(_:)),
            row: indexPath.row
        )

        return cell
    }

    @objc private func textFieldEditing(
        _ textField: UITextField
    ) {
        let row = textField.tag

        guard viewModels.indices.contains(row) else {
            return
        }

        viewModels[row].text = textField.text
    }
}

// MARK: - PaymentDelegate

extension DemoController: PaymentDelegate {

    func onPaymentClosed() {
        print("Payment form was closed")
    }

    func onPaymentFinished(_ transactionId: Int64?) {

        if let transactionId = transactionId {
            print("Transaction finished with ID: \(transactionId)")
        }
    }

    func onPaymentFailed(_ errorMessage: String?) {
        if let errorMessage = errorMessage {
            print("Transaction failed with error: \(errorMessage)")
        }
    }
}

// MARK: - PaymentUIDelegate

extension DemoController: PaymentUIDelegate {
    
    func paymentFormWillDisplay() {
        print("Payment form will display")
    }
    
    func paymentFormDidDisplay() {
        print("Payment form did display")
    }
    
    func paymentFormWillHide() {
        print("Payment form will hide")
    }
    
    func paymentFormDidHide() {
        print("Payment form did hide")
    }
}
