//
//  ProgressSbpView.swift
//  sdk
//
//  Created by Cloudpayments on 02.05.2024.
//  Copyright © 2024 Cloudpayments. All rights reserved.
//

import Foundation
import UIKit

// MARK: - CustomSbpViewDelegate

protocol CustomSbpViewDelegate: AnyObject {
    
    func numberOfRow(
        _ progressSbpView: ProgressSbpView,
        didChange text: String
    )
    
    func searchBarCancelButtonClicked(
        _ progressSbpView: ProgressSbpView
    )
    
    func numberOfRow(
        _ progressSbpView: ProgressSbpView
    ) -> Int
    
    func progressSbpView(
        _ progressSbpView: ProgressSbpView,
        cellFor row: Int
    ) -> Bank
    
    func progressSbpView(
        _ progressSbpView: ProgressSbpView,
        didSelect row: Int
    )
}


// MARK: - ProgressSbpView

final class ProgressSbpView: UIView {
    
    weak var delegate: CustomSbpViewDelegate?
    
    // MARK: - Private properties
    
    private var notFoundBanksView =
    UIView(
        backgroundColor: .white
    )
    
    private lazy var sbpTableView: UITableView = {
        let tableView = UITableView(
            frame: .zero,
            style: .plain
        )
        
        tableView.register(
            ProgressSbpCell.self,
            forCellReuseIdentifier:
                ProgressSbpCell.identifier
        )
        
        tableView.rowHeight =
        UITableView.automaticDimension
        
        tableView.contentInset.bottom =
        contentInsetBottom
        
        return tableView
    }()
    
    private var notFoundBanksLabel =
    UILabel(
        text: .notFound,
        textColor: .black,
        fontSize: 18
    )
    
    private var searchBar =
    UISearchBar()
    
    private var sbpImageView =
    UIImageView()
    
    private var defaultBorderColor: CGColor?
    private var tableViewHeightConstraint:
    NSLayoutConstraint!
    
    private let contentInsetBottom: CGFloat = 50
    
    // MARK: - DidMoveToSuperview
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        sbpTableView.delegate = self
        sbpTableView.dataSource = self
        searchBar.delegate = self
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        setupConstraintsAndView()
        customizeSearchBar()
        setupImage()
        
        layer.cornerRadius = 20
        
        layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateHeightTableViewContent()
    }
    
    // MARK: - Public
    
    func reloadData() {
        sbpTableView.reloadData()
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            
            self.sbpTableView.layoutIfNeeded()
            
            self.updateHeightTableViewContent()
            
            self.setNeedsLayout()
            
            self.superview?.setNeedsLayout()
        }
    }
    
    func updateOrientationLayout() {
        setNeedsLayout()
        layoutIfNeeded()
        
        sbpTableView.setNeedsLayout()
        sbpTableView.layoutIfNeeded()
        
        updateHeightTableViewContent()
    }
    
    // MARK: - Private methods
    
    private func setupImage() {
        sbpImageView.contentMode =
            .scaleAspectFit
        
        sbpImageView.clipsToBounds =
        true
        
        sbpImageView.image =
        UIImage.icn_sbp_logo
        
        sbpTableView.backgroundColor =
            .clear
    }
    
    private func updateHeightTableViewContent() {
        let screenSize: CGSize
        
        if let window {
            screenSize = window.bounds.size
        } else if let superview {
            screenSize = superview.bounds.size
        } else {
            screenSize = UIScreen.main.bounds.size
        }
        
        let isLandscape =
        screenSize.width > screenSize.height
        
        let maxRowsHeight: CGFloat =
        isLandscape
        ? 165
        : 350
        
        let contentHeight =
        sbpTableView.contentSize.height
        
        let rowsHeight: CGFloat
        
        if contentHeight > 0 {
            rowsHeight = min(
                contentHeight,
                maxRowsHeight
            )
        } else {
            rowsHeight = maxRowsHeight
        }
        
        let finalHeight =
        rowsHeight + contentInsetBottom
        
        if abs(
            tableViewHeightConstraint.constant
            - finalHeight
        ) > 0.5 {
            
            tableViewHeightConstraint.constant =
            finalHeight
        }
    }
    
    private func customizeSearchBar() {
        searchBar.layer.cornerRadius = 8
        searchBar.clipsToBounds = true
        
        searchBar.layer.borderWidth = 2
        
        searchBar.layer.borderColor =
        UIColor(
            red: 0.89,
            green: 0.91,
            blue: 0.94,
            alpha: 1
        ).cgColor
        
        defaultBorderColor =
        searchBar.layer.borderColor
        
        searchBar.barTintColor =
            .white
        
        searchBar.backgroundColor =
            .white
        
        searchBar.placeholder =
            .searchBankApp
        
        notFoundBanksLabel.textColor =
        UIColor(
            red: 0.55,
            green: 0.58,
            blue: 0.62,
            alpha: 1
        )
        
        if let textfield =
            searchBar.value(
                forKey: "searchField"
            ) as? UITextField {
            
            textfield.textColor =
            UIColor(
                red: 0.15,
                green: 0.15,
                blue: 0.27,
                alpha: 1
            )
            
            textfield.backgroundColor =
                .white
        }
    }
    
    private func setupConstraintsAndView() {
        
        let topContentView =
        UIView()
        
        let iconView =
        UIImageView()
        
        iconView.image =
        UIImage.icon_not_found_banks
        
        let defaultLineView =
        UIView()
        
        let blackView =
        UIView()
        
        let leftView =
        UIView()
        
        let rightView =
        UIView()
        
        let headerStackView =
        UIStackView(
            .horizontal,
            .fill,
            .fill,
            24,
            [
                leftView,
                rightView
            ]
        )
        
        let stackView =
        UIStackView(
            .vertical,
            .equalSpacing,
            .fill,
            12,
            [
                headerStackView,
                searchBar
            ]
        )
        
        let label =
        UILabel(
            text: .chooseBank,
            textColor: .black,
            fontSize: 17
        )
        
        label.textAlignment = .left
        
        label.textColor =
        UIColor(
            red: 0.27,
            green: 0.3,
            blue: 0.36,
            alpha: 1
        )
        
        iconView.contentMode =
            .scaleAspectFit
        
        topContentView.backgroundColor =
            .clear
        
        blackView.clipsToBounds =
        true
        
        blackView.backgroundColor =
            .black
        
        blackView.layer.cornerRadius =
        2
        
        addSubviews(
            topContentView,
            notFoundBanksView,
            sbpTableView
        )
        
        notFoundBanksView.addSubviews(
            iconView,
            notFoundBanksLabel
        )
        
        topContentView.addSubviews(
            defaultLineView,
            stackView
        )
        
        defaultLineView.addSubviews(
            blackView
        )
        
        leftView.addSubviews(
            sbpImageView
        )
        
        rightView.addSubviews(
            label
        )
        
        sbpTableView.layer.borderColor =
        UIColor(
            red: 0.886,
            green: 0.91,
            blue: 0.937,
            alpha: 1
        ).cgColor
        
        sbpTableView.layer.borderWidth =
        1
        
        NSLayoutConstraint.activate([
            
            // MARK: Top content
            
            topContentView.topAnchor.constraint(
                equalTo: topAnchor
            ),
            
            topContentView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            
            topContentView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            
            // MARK: Table
            
            sbpTableView.topAnchor.constraint(
                equalTo: topContentView.bottomAnchor,
                constant: 8
            ),
            
            sbpTableView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            
            sbpTableView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            
            sbpTableView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),
            
            // MARK: Not found
            
            notFoundBanksView.topAnchor.constraint(
                equalTo: sbpTableView.topAnchor
            ),
            
            notFoundBanksView.bottomAnchor.constraint(
                equalTo: sbpTableView.bottomAnchor
            ),
            
            notFoundBanksView.leadingAnchor.constraint(
                equalTo: sbpTableView.leadingAnchor
            ),
            
            notFoundBanksView.trailingAnchor.constraint(
                equalTo: sbpTableView.trailingAnchor
            ),
            
            iconView.topAnchor.constraint(
                greaterThanOrEqualTo:
                    notFoundBanksView.topAnchor,
                constant: 30
            ),
            
            iconView.centerXAnchor.constraint(
                equalTo:
                    notFoundBanksView.centerXAnchor
            ),
            
            iconView.heightAnchor.constraint(
                equalToConstant: 60
            ),
            
            iconView.widthAnchor.constraint(
                equalTo: iconView.heightAnchor
            ),
            
            notFoundBanksLabel.topAnchor.constraint(
                equalTo:
                    iconView.bottomAnchor,
                constant: 20
            ),
            
            notFoundBanksLabel.leadingAnchor.constraint(
                equalTo:
                    notFoundBanksView.leadingAnchor,
                constant: 65
            ),
            
            notFoundBanksLabel.trailingAnchor.constraint(
                equalTo:
                    notFoundBanksView.trailingAnchor,
                constant: -65
            ),
            
            // MARK: Default line view
            
            defaultLineView.topAnchor.constraint(
                equalTo: topContentView.topAnchor
            ),
            
            defaultLineView.leadingAnchor.constraint(
                equalTo:
                    topContentView.leadingAnchor
            ),
            
            defaultLineView.trailingAnchor.constraint(
                equalTo:
                    topContentView.trailingAnchor
            ),
            
            defaultLineView.heightAnchor.constraint(
                equalToConstant: 34
            ),
            
            // MARK: Stack
            
            stackView.topAnchor.constraint(
                equalTo:
                    defaultLineView.bottomAnchor,
                constant: 5
            ),
            
            stackView.leadingAnchor.constraint(
                equalTo:
                    topContentView.leadingAnchor,
                constant: 24
            ),
            
            stackView.trailingAnchor.constraint(
                equalTo:
                    topContentView.trailingAnchor,
                constant: -20
            ),
            
            stackView.bottomAnchor.constraint(
                equalTo:
                    topContentView.bottomAnchor,
                constant: -10
            ),
            
            // MARK: Handle
            
            blackView.bottomAnchor.constraint(
                equalTo:
                    defaultLineView.bottomAnchor,
                constant: -8
            ),
            
            blackView.heightAnchor.constraint(
                equalToConstant: 5
            ),
            
            blackView.widthAnchor.constraint(
                equalToConstant: 135
            ),
            
            blackView.centerXAnchor.constraint(
                equalTo:
                    defaultLineView.centerXAnchor
            ),
            
            // MARK: Search bar
            
            searchBar.heightAnchor.constraint(
                equalToConstant: 48
            ),
            
            // MARK: SBP logo
            
            sbpImageView.heightAnchor.constraint(
                equalToConstant: 46
            ),
            
            sbpImageView.widthAnchor.constraint(
                equalToConstant: 78
            ),
            
            sbpImageView.centerYAnchor.constraint(
                equalTo:
                    leftView.centerYAnchor
            ),
            
            sbpImageView.topAnchor.constraint(
                greaterThanOrEqualTo:
                    leftView.topAnchor
            ),
            
            sbpImageView.leadingAnchor.constraint(
                equalTo:
                    leftView.leadingAnchor
            ),
            
            sbpImageView.trailingAnchor.constraint(
                equalTo:
                    leftView.trailingAnchor
            ),
            
            // MARK: Label near SBP image
            
            label.topAnchor.constraint(
                equalTo:
                    rightView.topAnchor
            ),
            
            label.leadingAnchor.constraint(
                equalTo:
                    rightView.leadingAnchor
            ),
            
            label.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    rightView.trailingAnchor
            ),
            
            label.bottomAnchor.constraint(
                equalTo:
                    rightView.bottomAnchor
            )
        ])
        tableViewHeightConstraint =
        sbpTableView.heightAnchor.constraint(
            equalToConstant:
                350 + contentInsetBottom
        )
        
        tableViewHeightConstraint.isActive =
        true
    }
}


// MARK: - UISearchBarDelegate

extension ProgressSbpView: UISearchBarDelegate {
    
    func searchBar(
        _ searchBar: UISearchBar,
        textDidChange searchText: String
    ) {
        delegate?.numberOfRow(
            self,
            didChange: searchText
        )
    }
    
    func searchBarCancelButtonClicked(
        _ searchBar: UISearchBar
    ) {
        searchBar.text = ""
        
        searchBar.resignFirstResponder()
        
        delegate?
            .searchBarCancelButtonClicked(
                self
            )
    }
    
    func searchBarTextDidBeginEditing(
        _ searchBar: UISearchBar
    ) {
        searchBar.layer.borderColor =
        UIColor(
            red: 0.18,
            green: 0.44,
            blue: 0.99,
            alpha: 1
        ).cgColor
    }
    
    func searchBarTextDidEndEditing(
        _ searchBar: UISearchBar
    ) {
        searchBar.layer.borderColor =
        defaultBorderColor
    }
}


// MARK: - UITableViewDelegate / UITableViewDataSource

extension ProgressSbpView:
    UITableViewDelegate,
    UITableViewDataSource {
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        let count =
        delegate?
            .numberOfRow(self)
        ?? 0
        
        notFoundBanksView.isHidden =
        count > 0
        
        return count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        guard
            let value =
                delegate?
                .progressSbpView(
                    self,
                    cellFor: indexPath.row
                ),
            
                let cell =
                tableView.dequeueReusableCell(
                    withIdentifier:
                        ProgressSbpCell.identifier,
                    for: indexPath
                ) as? ProgressSbpCell
        else {
            return UITableViewCell()
        }
        
        cell.configureCell(
            model: value
        )
        
        return cell
    }
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        delegate?
            .progressSbpView(
                self,
                didSelect: indexPath.row
            )
    }
}
