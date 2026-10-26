//
//  PaymentViewModel.swift
//  demo
//
//  Created by Cloudpayments on 27.06.2023.
//  Copyright © 2023 Cloudpayments. All rights reserved.
//

import UIKit
import Foundation

// MARK: - PaymentViewModelType

enum PaymentViewModelType: Codable {
    case publicId
    case amount
    case currency
    case invoiceId
    case description
    case accountId
    case email
    case jsonData

    var title: String {
        switch self {
        case .publicId:
            return "PublicId"

        case .amount:
            return "Amount"

        case .currency:
            return "Currency (Optional)"

        case .invoiceId:
            return "InvoiceId (Optional)"

        case .description:
            return "Description (Optional)"

        case .accountId:
            return "AccountId (Optional)"

        case .email:
            return "Email (Optional)"

        case .jsonData:
            return "JsonData (Optional)"
        }
    }

    var `default`: String {
        switch self {
        case .publicId:
            return "test_api_00000000000000000000002"

        case .amount:
            return "100"

        case .currency:
            return "RUB"

        case .invoiceId:
            return "AB1234"

        case .description:
            return "A basket of oranges"

        case .accountId:
            return "AB12"

        case .email:
            return "test@cp.ru"

        case .jsonData:
            return "{\"name\": \"Ivan\"}"
        }
    }

    var placeholder: String {
        return "Введите текст"
    }
}

// MARK: - PaymentViewModel

struct PaymentViewModel: Codable {

    private static var key: String {
        return "PaymentViewModel_Key"
    }

    let type: PaymentViewModelType
    var text: String?

    init(_ type: PaymentViewModelType) {
        self.type = type
        self.text = type.default
    }

    static func defaultViewModels() -> [PaymentViewModel] {
        return [
            .init(.publicId),
            .init(.amount),
            .init(.currency),
            .init(.invoiceId),
            .init(.description),
            .init(.accountId),
            .init(.email),
            .init(.jsonData)
        ]
    }

    static func getViewModel() -> [PaymentViewModel] {
        guard
            let data = UserDefaults.standard.data(forKey: PaymentViewModel.key),
            let array = try? JSONDecoder().decode(
                [PaymentViewModel].self,
                from: data
            )
        else {
            return defaultViewModels()
        }

        return array
    }

    static func saving(_ model: [PaymentViewModel]) {
        guard let data = try? JSONEncoder().encode(model) else {
            print("Не удалось закодировать PaymentViewModel")
            return
        }

        UserDefaults.standard.set(data, forKey: PaymentViewModel.key)
    }

    static func resetCurrentConfiguration() {
        UserDefaults.standard.removeObject(forKey: PaymentViewModel.key)
    }
}

// MARK: - SavedPaymentConfiguration

struct SavedPaymentConfiguration: Codable {

    let id: UUID
    var name: String
    var fields: [PaymentViewModel]
    var isDualMessagePaymentEnabled: Bool
    var isRecurrentEnabled: Bool
    var isReceiptEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        fields: [PaymentViewModel],
        isDualMessagePaymentEnabled: Bool,
        isRecurrentEnabled: Bool,
        isReceiptEnabled: Bool
    ) {
        self.id = id
        self.name = name
        self.fields = fields
        self.isDualMessagePaymentEnabled = isDualMessagePaymentEnabled
        self.isRecurrentEnabled = isRecurrentEnabled
        self.isReceiptEnabled = isReceiptEnabled
    }
}

// MARK: - SavedPaymentConfigurationStorage

final class SavedPaymentConfigurationStorage {

    static let shared = SavedPaymentConfigurationStorage()

    private let storageKey = "SavedPaymentConfigurations_Key"

    private init() {}

    func getConfigurations() -> [SavedPaymentConfiguration] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let configurations = try? JSONDecoder().decode(
                [SavedPaymentConfiguration].self,
                from: data
            )
        else {
            return []
        }

        return configurations
    }

    func saveConfiguration(_ configuration: SavedPaymentConfiguration) {
        var configurations = getConfigurations()

        if let index = configurations.firstIndex(where: {
            $0.name.caseInsensitiveCompare(configuration.name) == .orderedSame
        }) {
            var updatedConfiguration = configuration
            updatedConfiguration = SavedPaymentConfiguration(
                id: configurations[index].id,
                name: configuration.name,
                fields: configuration.fields,
                isDualMessagePaymentEnabled:
                    configuration.isDualMessagePaymentEnabled,
                isRecurrentEnabled: configuration.isRecurrentEnabled,
                isReceiptEnabled: configuration.isReceiptEnabled
            )

            configurations[index] = updatedConfiguration

            print(
                "Конфигурация обновлена: \(configuration.name)"
            )
        } else {
            configurations.append(configuration)

            print(
                "Конфигурация сохранена: \(configuration.name)"
            )
        }

        saveConfigurations(configurations)
    }

    func deleteConfiguration(id: UUID) {
        var configurations = getConfigurations()

        configurations.removeAll {
            $0.id == id
        }

        saveConfigurations(configurations)

        print(
            "Конфигурация удалена: \(id)"
        )
    }

    private func saveConfigurations(
        _ configurations: [SavedPaymentConfiguration]
    ) {
        guard
            let data = try? JSONEncoder().encode(configurations)
        else {
            print("Не удалось сохранить конфигурации")
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }
}


// MARK: - DemoViewCell

final class DemoViewCell: UITableViewCell {

    static let reuseIdentifier =
        String(describing: DemoViewCell.self)

    // MARK: - Private UI

    private let containerView = UIView()
    private let demoLabel = UILabel()
    private let demoTextField = UITextField()

    private let borderBlueColor = UIColor(
        red: 0.25,
        green: 0.42,
        blue: 0.95,
        alpha: 1
    )

    // MARK: - Init

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(
            style: style,
            reuseIdentifier: reuseIdentifier
        )

        setupView()
        setupConstraints()
        setupTextField()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupView()
        setupConstraints()
        setupTextField()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        demoTextField.removeTarget(
            nil,
            action: nil,
            for: .editingChanged
        )

        demoTextField.text = nil
        demoTextField.placeholder = nil
        demoLabel.text = nil
    }

    // MARK: - Public methods

    func setupView(
        viewModel: PaymentViewModel
    ) {
        demoLabel.text = viewModel.type.title
        demoTextField.placeholder =
            viewModel.type.placeholder
        demoTextField.text = viewModel.text
    }

    func addTarget(
        _ target: Any,
        action: Selector,
        row: Int
    ) {
        demoTextField.tag = row

        demoTextField.addTarget(
            target,
            action: action,
            for: .editingChanged
        )
    }

    // MARK: - Private methods

    private func setupView() {
        selectionStyle = .none

        backgroundColor = .clear
        contentView.backgroundColor = .white

        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 18
        containerView.layer.borderWidth = 0
        containerView.layer.borderColor = nil
        containerView.clipsToBounds = true

        demoLabel.font = .systemFont(
            ofSize: 16,
            weight: .semibold
        )

        demoLabel.textColor = .black
        demoLabel.numberOfLines = 0

        contentView.addSubview(containerView)
        containerView.addSubview(demoLabel)
        containerView.addSubview(demoTextField)
    }

    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints =
            false

        demoLabel.translatesAutoresizingMaskIntoConstraints =
            false

        demoTextField.translatesAutoresizingMaskIntoConstraints =
            false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 6
            ),
            containerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            containerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            containerView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -6
            ),

            demoLabel.topAnchor.constraint(
                equalTo: containerView.topAnchor,
                constant: 16
            ),
            demoLabel.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor,
                constant: 14
            ),
            demoLabel.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: -14
            ),

            demoTextField.topAnchor.constraint(
                equalTo: demoLabel.bottomAnchor,
                constant: 10
            ),
            demoTextField.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor,
                constant: 14
            ),
            demoTextField.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: -14
            ),
            demoTextField.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor,
                constant: -14
            ),
            demoTextField.heightAnchor.constraint(
                equalToConstant: 56
            )
        ])
    }

    private func setupTextField() {
        demoTextField.backgroundColor = .white
        demoTextField.textColor = .black
        demoTextField.tintColor = borderBlueColor

        demoTextField.font = .systemFont(
            ofSize: 17,
            weight: .regular
        )

        demoTextField.borderStyle = .none

        demoTextField.layer.cornerRadius = 14
        demoTextField.layer.borderWidth = 1.5
        demoTextField.layer.borderColor =
            borderBlueColor.cgColor

        demoTextField.clipsToBounds = true

        demoTextField.leftView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 14,
                height: 1
            )
        )

        demoTextField.leftViewMode = .always

        demoTextField.rightView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 14,
                height: 1
            )
        )

        demoTextField.rightViewMode = .always

        demoTextField.autocorrectionType = .no
        demoTextField.autocapitalizationType = .none
        demoTextField.clearButtonMode = .whileEditing
    }
}

// MARK: - FooterActionView

final class FooterActionView: UIView {

    enum ButtonType {
        case demo
    }

    // MARK: - Public UI

    let demoActionButton = UIButton(type: .system)

    // MARK: - Public state

    var isDualMessagePaymentEnabled: Bool {
        return dualMessageSwitch.isOn
    }

    var isRecurrentEnabled: Bool {
        return recurrentSwitch.isOn
    }

    var isReceiptEnabled: Bool {
        return receiptSwitch.isOn
    }

    // MARK: - Private UI

    private let contentView = UIView()

    private let dualMessageContainerView = UIView()
    private let dualMessageTitleLabel = UILabel()
    private let dualMessageSwitch = UISwitch()
    private let dualMessageStateLabel = UILabel()
    private let dualMessageStackView = UIStackView()

    private let recurrentContainerView = UIView()
    private let recurrentTitleLabel = UILabel()
    private let recurrentSwitch = UISwitch()
    private let recurrentStateLabel = UILabel()
    private let recurrentStackView = UIStackView()

    private let receiptContainerView = UIView()
    private let receiptTitleLabel = UILabel()
    private let receiptSwitch = UISwitch()
    private let receiptStateLabel = UILabel()
    private let receiptStackView = UIStackView()

    private let borderBlueColor = UIColor(
        red: 0.25,
        green: 0.42,
        blue: 0.95,
        alpha: 1
    )

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupView()
        setupConstraints()
    }

    // MARK: - Public methods

    func addTarget(
        target: Any?,
        action: Selector,
        _ type: ButtonType
    ) {
        switch type {
        case .demo:
            demoActionButton.addTarget(
                target,
                action: action,
                for: .touchUpInside
            )
        }
    }

    func setState(
        isDualMessagePaymentEnabled: Bool,
        isRecurrentEnabled: Bool,
        isReceiptEnabled: Bool
    ) {
        dualMessageSwitch.setOn(
            isDualMessagePaymentEnabled,
            animated: false
        )

        recurrentSwitch.setOn(
            isRecurrentEnabled,
            animated: false
        )

        receiptSwitch.setOn(
            isReceiptEnabled,
            animated: false
        )

        updateStateLabels()
    }

    func resetState() {
        setState(
            isDualMessagePaymentEnabled: false,
            isRecurrentEnabled: false,
            isReceiptEnabled: false
        )
    }

    // MARK: - Private methods

    private func setupView() {
        backgroundColor = .white

        setupContainer(dualMessageContainerView)
        setupContainer(recurrentContainerView)
        setupContainer(receiptContainerView)

        setupTitleLabel(
            dualMessageTitleLabel,
            text: "Dual message payment"
        )

        setupTitleLabel(
            recurrentTitleLabel,
            text: "Add recurrent"
        )

        setupTitleLabel(
            receiptTitleLabel,
            text: "Add receipt"
        )

        setupStateLabel(dualMessageStateLabel)
        setupStateLabel(recurrentStateLabel)
        setupStateLabel(receiptStateLabel)

        updateStateLabels()

        setupSwitchStackView(
            dualMessageStackView,
            switchView: dualMessageSwitch,
            label: dualMessageStateLabel
        )

        setupSwitchStackView(
            recurrentStackView,
            switchView: recurrentSwitch,
            label: recurrentStateLabel
        )

        setupSwitchStackView(
            receiptStackView,
            switchView: receiptSwitch,
            label: receiptStateLabel
        )

        dualMessageSwitch.addTarget(
            self,
            action: #selector(switchValueChanged(_:)),
            for: .valueChanged
        )

        recurrentSwitch.addTarget(
            self,
            action: #selector(switchValueChanged(_:)),
            for: .valueChanged
        )

        receiptSwitch.addTarget(
            self,
            action: #selector(switchValueChanged(_:)),
            for: .valueChanged
        )

        configureDemoActionButton()

        addSubview(contentView)

        contentView.addSubview(
            dualMessageContainerView
        )

        dualMessageContainerView.addSubview(
            dualMessageTitleLabel
        )

        dualMessageContainerView.addSubview(
            dualMessageStackView
        )

        contentView.addSubview(
            recurrentContainerView
        )

        recurrentContainerView.addSubview(
            recurrentTitleLabel
        )

        recurrentContainerView.addSubview(
            recurrentStackView
        )

        contentView.addSubview(
            receiptContainerView
        )

        receiptContainerView.addSubview(
            receiptTitleLabel
        )

        receiptContainerView.addSubview(
            receiptStackView
        )

        contentView.addSubview(demoActionButton)
    }

    private func configureDemoActionButton() {
        if #available(iOS 15.0, *) {
            var configuration =
                UIButton.Configuration.filled()

            configuration.title = "Запустить SDK"
            configuration.image =
                UIImage(systemName: "play.fill")

            configuration.imagePlacement = .leading
            configuration.imagePadding = 8
            configuration.baseForegroundColor = .white
            configuration.baseBackgroundColor = .black
            configuration.cornerStyle = .fixed
            configuration.background.cornerRadius = 18

            configuration.contentInsets =
                NSDirectionalEdgeInsets(
                    top: 14,
                    leading: 20,
                    bottom: 14,
                    trailing: 20
                )

            demoActionButton.configuration =
                configuration
        } else {
            demoActionButton.setTitle(
                "Запустить SDK",
                for: .normal
            )

            demoActionButton.setTitleColor(
                .white,
                for: .normal
            )

            demoActionButton.titleLabel?.font =
                .systemFont(
                    ofSize: 16,
                    weight: .semibold
                )

            demoActionButton.backgroundColor = .black

            demoActionButton.setImage(
                UIImage(systemName: "play.fill"),
                for: .normal
            )

            demoActionButton.tintColor = .white
            demoActionButton.semanticContentAttribute =
                .forceLeftToRight

            demoActionButton.contentEdgeInsets =
                UIEdgeInsets(
                    top: 14,
                    left: 20,
                    bottom: 14,
                    right: 20
                )
        }

        demoActionButton.layer.cornerRadius = 18
        demoActionButton.clipsToBounds = true
    }

    private func setupContainer(_ view: UIView) {
        view.backgroundColor = .white
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1.5
        view.layer.borderColor =
            borderBlueColor.cgColor
        view.clipsToBounds = true
    }

    private func setupTitleLabel(
        _ label: UILabel,
        text: String
    ) {
        label.text = text

        label.font = .systemFont(
            ofSize: 16,
            weight: .semibold
        )

        label.textColor = .black
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
    }

    private func setupStateLabel(
        _ label: UILabel
    ) {
        label.font = .systemFont(
            ofSize: 17,
            weight: .regular
        )

        label.textColor = .black
        label.numberOfLines = 1

        label.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
    }

    private func setupSwitchStackView(
        _ stackView: UIStackView,
        switchView: UISwitch,
        label: UILabel
    ) {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12

        switchView
            .setContentCompressionResistancePriority(
                .required,
                for: .horizontal
            )

        label
            .setContentCompressionResistancePriority(
                .defaultLow,
                for: .horizontal
            )

        stackView.addArrangedSubview(switchView)
        stackView.addArrangedSubview(label)
    }

    private func updateStateLabels() {
        dualMessageStateLabel.text =
            dualMessageSwitch.isOn
            ? "Включено"
            : "Выключено"

        recurrentStateLabel.text =
            recurrentSwitch.isOn
            ? "Включено"
            : "Выключено"

        receiptStateLabel.text =
            receiptSwitch.isOn
            ? "Включено"
            : "Выключено"
    }

    private func setupConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints =
            false

        dualMessageContainerView
            .translatesAutoresizingMaskIntoConstraints = false

        dualMessageTitleLabel
            .translatesAutoresizingMaskIntoConstraints = false

        dualMessageStackView
            .translatesAutoresizingMaskIntoConstraints = false

        recurrentContainerView
            .translatesAutoresizingMaskIntoConstraints = false

        recurrentTitleLabel
            .translatesAutoresizingMaskIntoConstraints = false

        recurrentStackView
            .translatesAutoresizingMaskIntoConstraints = false

        receiptContainerView
            .translatesAutoresizingMaskIntoConstraints = false

        receiptTitleLabel
            .translatesAutoresizingMaskIntoConstraints = false

        receiptStackView
            .translatesAutoresizingMaskIntoConstraints = false

        demoActionButton
            .translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(
                equalTo: topAnchor
            ),
            contentView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            contentView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            contentView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),

            dualMessageContainerView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 12
            ),
            dualMessageContainerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            dualMessageContainerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            dualMessageContainerView.heightAnchor.constraint(
                equalToConstant: 88
            ),

            dualMessageTitleLabel.topAnchor.constraint(
                equalTo: dualMessageContainerView.topAnchor,
                constant: 14
            ),
            dualMessageTitleLabel.leadingAnchor.constraint(
                equalTo: dualMessageContainerView.leadingAnchor,
                constant: 14
            ),
            dualMessageTitleLabel.trailingAnchor.constraint(
                equalTo: dualMessageContainerView.trailingAnchor,
                constant: -14
            ),

            dualMessageStackView.topAnchor.constraint(
                equalTo: dualMessageTitleLabel.bottomAnchor,
                constant: 10
            ),
            dualMessageStackView.leadingAnchor.constraint(
                equalTo: dualMessageContainerView.leadingAnchor,
                constant: 14
            ),
            dualMessageStackView.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    dualMessageContainerView.trailingAnchor,
                constant: -14
            ),

            recurrentContainerView.topAnchor.constraint(
                equalTo:
                    dualMessageContainerView.bottomAnchor,
                constant: 10
            ),
            recurrentContainerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            recurrentContainerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            recurrentContainerView.heightAnchor.constraint(
                equalToConstant: 88
            ),

            recurrentTitleLabel.topAnchor.constraint(
                equalTo: recurrentContainerView.topAnchor,
                constant: 14
            ),
            recurrentTitleLabel.leadingAnchor.constraint(
                equalTo: recurrentContainerView.leadingAnchor,
                constant: 14
            ),
            recurrentTitleLabel.trailingAnchor.constraint(
                equalTo: recurrentContainerView.trailingAnchor,
                constant: -14
            ),

            recurrentStackView.topAnchor.constraint(
                equalTo: recurrentTitleLabel.bottomAnchor,
                constant: 10
            ),
            recurrentStackView.leadingAnchor.constraint(
                equalTo: recurrentContainerView.leadingAnchor,
                constant: 14
            ),
            recurrentStackView.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    recurrentContainerView.trailingAnchor,
                constant: -14
            ),

            receiptContainerView.topAnchor.constraint(
                equalTo:
                    recurrentContainerView.bottomAnchor,
                constant: 10
            ),
            receiptContainerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            receiptContainerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            receiptContainerView.heightAnchor.constraint(
                equalToConstant: 88
            ),

            receiptTitleLabel.topAnchor.constraint(
                equalTo: receiptContainerView.topAnchor,
                constant: 14
            ),
            receiptTitleLabel.leadingAnchor.constraint(
                equalTo: receiptContainerView.leadingAnchor,
                constant: 14
            ),
            receiptTitleLabel.trailingAnchor.constraint(
                equalTo: receiptContainerView.trailingAnchor,
                constant: -14
            ),

            receiptStackView.topAnchor.constraint(
                equalTo: receiptTitleLabel.bottomAnchor,
                constant: 10
            ),
            receiptStackView.leadingAnchor.constraint(
                equalTo: receiptContainerView.leadingAnchor,
                constant: 14
            ),
            receiptStackView.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    receiptContainerView.trailingAnchor,
                constant: -14
            ),

            demoActionButton.topAnchor.constraint(
                equalTo: receiptContainerView.bottomAnchor,
                constant: 20
            ),
            demoActionButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            demoActionButton.heightAnchor.constraint(
                equalToConstant: 56
            )
        ])
    }

    @objc private func switchValueChanged(
        _ sender: UISwitch
    ) {
        updateStateLabels()
    }
}

// MARK: - SavedConfigurationCell

final class SavedConfigurationCell: UITableViewCell {

    static let reuseIdentifier =
        String(describing: SavedConfigurationCell.self)

    var onDelete: (() -> Void)?

    private let nameLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let separatorView = UIView()

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(
            style: style,
            reuseIdentifier: reuseIdentifier
        )

        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupView()
        setupConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
        onDelete = nil
    }

    func configure(
        name: String
    ) {
        nameLabel.text = name
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        nameLabel.font = .systemFont(
            ofSize: 16,
            weight: .medium
        )

        nameLabel.textColor = UIColor(
            red: 0.25,
            green: 0.42,
            blue: 0.95,
            alpha: 1
        )

        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail

        deleteButton.setImage(
            UIImage(systemName: "trash.fill"),
            for: .normal
        )

        deleteButton.tintColor = .darkGray

        deleteButton.addTarget(
            self,
            action: #selector(deleteButtonPressed),
            for: .touchUpInside
        )

        separatorView.backgroundColor =
            UIColor.black.withAlphaComponent(0.08)

        contentView.addSubview(nameLabel)
        contentView.addSubview(deleteButton)
        contentView.addSubview(separatorView)
    }

    private func setupConstraints() {
        nameLabel.translatesAutoresizingMaskIntoConstraints =
            false

        deleteButton
            .translatesAutoresizingMaskIntoConstraints = false

        separatorView
            .translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 4
            ),
            nameLabel.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            nameLabel.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    deleteButton.leadingAnchor,
                constant: -12
            ),

            deleteButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -4
            ),
            deleteButton.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            deleteButton.widthAnchor.constraint(
                equalToConstant: 44
            ),
            deleteButton.heightAnchor.constraint(
                equalToConstant: 44
            ),

            separatorView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            separatorView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            separatorView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),
            separatorView.heightAnchor.constraint(
                equalToConstant: 0.5
            )
        ])
    }

    @objc private func deleteButtonPressed() {
        onDelete?()
    }
}

// MARK: - SavedConfigurationsViewController

final class SavedConfigurationsViewController:
    UIViewController {

    var onConfigurationSelected:
        ((SavedPaymentConfiguration) -> Void)?

    private var configurations:
        [SavedPaymentConfiguration] = []

    private let dimmingView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let tableView = UITableView(
        frame: .zero,
        style: .plain
    )
    private let closeButton = UIButton(type: .system)

    private var containerHeightConstraint:
        NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        configurations =
            SavedPaymentConfigurationStorage
                .shared
                .getConfigurations()

        setupView()
        setupConstraints()
        updateContainerHeight()
    }

    private func setupView() {
        view.backgroundColor = .clear

        dimmingView.backgroundColor =
            UIColor.black.withAlphaComponent(0.45)

        let dimmingTap = UITapGestureRecognizer(
            target: self,
            action: #selector(closePressed)
        )

        dimmingView.addGestureRecognizer(dimmingTap)

        containerView.backgroundColor = UIColor(
            red: 0.96,
            green: 0.96,
            blue: 0.98,
            alpha: 1
        )

        containerView.layer.cornerRadius = 28
        containerView.layer.cornerCurve = .continuous
        containerView.clipsToBounds = true

        titleLabel.text = "Загрузить\nконфигурацию"

        titleLabel.font = .systemFont(
            ofSize: 24,
            weight: .regular
        )

        titleLabel.textColor = .darkText
        titleLabel.numberOfLines = 2

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 58
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(
            SavedConfigurationCell.self,
            forCellReuseIdentifier:
                SavedConfigurationCell.reuseIdentifier
        )

        closeButton.setTitle(
            "Закрыть",
            for: .normal
        )

        closeButton.titleLabel?.font = .systemFont(
            ofSize: 15,
            weight: .medium
        )

        closeButton.addTarget(
            self,
            action: #selector(closePressed),
            for: .touchUpInside
        )

        view.addSubview(dimmingView)
        view.addSubview(containerView)

        containerView.addSubview(titleLabel)
        containerView.addSubview(tableView)
        containerView.addSubview(closeButton)
    }

    private func setupConstraints() {
        dimmingView.translatesAutoresizingMaskIntoConstraints =
            false

        containerView
            .translatesAutoresizingMaskIntoConstraints = false

        titleLabel
            .translatesAutoresizingMaskIntoConstraints = false

        tableView
            .translatesAutoresizingMaskIntoConstraints = false

        closeButton
            .translatesAutoresizingMaskIntoConstraints = false

        containerHeightConstraint =
            containerView.heightAnchor.constraint(
                equalToConstant: 250
            )

        containerHeightConstraint?.isActive = true

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
            ),

            containerView.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            containerView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            containerView.leadingAnchor.constraint(
                greaterThanOrEqualTo:
                    view.leadingAnchor,
                constant: 20
            ),
            containerView.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    view.trailingAnchor,
                constant: -20
            ),
            containerView.widthAnchor.constraint(
                equalToConstant: 330
            ),

            titleLabel.topAnchor.constraint(
                equalTo: containerView.topAnchor,
                constant: 24
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor,
                constant: 24
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: -24
            ),

            tableView.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 12
            ),
            tableView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor,
                constant: 24
            ),
            tableView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: -24
            ),

            closeButton.topAnchor.constraint(
                equalTo: tableView.bottomAnchor,
                constant: 10
            ),
            closeButton.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: -24
            ),
            closeButton.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor,
                constant: -18
            ),
            closeButton.heightAnchor.constraint(
                equalToConstant: 36
            )
        ])
    }

    private func updateContainerHeight() {
        let visibleRows = min(
            configurations.count,
            5
        )

        let rowsHeight =
            CGFloat(visibleRows) * tableView.rowHeight

        let calculatedHeight =
            24
            + 58
            + 12
            + rowsHeight
            + 10
            + 36
            + 18

        containerHeightConstraint?.constant =
            max(210, calculatedHeight)

        tableView.isScrollEnabled =
            configurations.count > 5
    }

    private func deleteConfiguration(
        at indexPath: IndexPath
    ) {
        guard configurations.indices.contains(
            indexPath.row
        ) else {
            return
        }

        let configuration =
            configurations[indexPath.row]

        let alert = UIAlertController(
            title: "Удалить конфигурацию?",
            message: configuration.name,
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
                title: "Удалить",
                style: .destructive,
                handler: { [weak self] _ in
                    guard let self else {
                        return
                    }

                    SavedPaymentConfigurationStorage
                        .shared
                        .deleteConfiguration(
                            id: configuration.id
                        )

                    self.configurations.remove(
                        at: indexPath.row
                    )

                    if self.configurations.isEmpty {
                        self.dismiss(
                            animated: true
                        )

                        return
                    }

                    self.tableView.deleteRows(
                        at: [indexPath],
                        with: .automatic
                    )

                    self.updateContainerHeight()

                    UIView.animate(
                        withDuration: 0.25
                    ) {
                        self.view.layoutIfNeeded()
                    }
                }
            )
        )

        present(
            alert,
            animated: true
        )
    }

    @objc private func closePressed() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SavedConfigurationsViewController:
    UITableViewDataSource,
    UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return configurations.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier:
                    SavedConfigurationCell.reuseIdentifier,
                for: indexPath
            ) as? SavedConfigurationCell
        else {
            return UITableViewCell()
        }

        let configuration =
            configurations[indexPath.row]

        cell.configure(
            name: configuration.name
        )

        cell.onDelete = { [weak self, weak tableView] in
            guard
                let self,
                let tableView,
                let currentIndexPath =
                    tableView.indexPath(for: cell)
            else {
                return
            }

            self.deleteConfiguration(
                at: currentIndexPath
            )
        }

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        guard configurations.indices.contains(
            indexPath.row
        ) else {
            return
        }

        let configuration =
            configurations[indexPath.row]

        dismiss(
            animated: true
        ) { [weak self] in
            self?.onConfigurationSelected?(
                configuration
            )
        }
    }
}
