//
//  Button.swift
//  sdk
//
//  Created by Sergey Iskhakov on 17.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import UIKit

final class CPButton: UIButton {

    var onAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        configuration = .plain()
    }

    @objc private func handleTap() { onAction?() }

    func setPadding(_ insets: NSDirectionalEdgeInsets) {
        var cfg = configuration ?? .plain()
        cfg.contentInsets = insets
        configuration = cfg
    }

    func setIcon(_ image: UIImage?) {
        var cfg = configuration ?? .plain()
        cfg.image = image
        configuration = cfg
    }
}

class Button: UIButton {
    var onAction: (()->())?
    
    @IBInspectable var borderWidth : CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth;
        }
    }
    @IBInspectable var borderColor : UIColor = UIColor.clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    @IBInspectable var cornerRadius : CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    func setAlpha(_ alpha: CGFloat) {
        self.alpha = alpha
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(onAction(_:)), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addTarget(self, action: #selector(onAction(_:)), for: .touchUpInside)
    }
    
    @objc func onAction(_ sender: Any) {
        if self.onAction != nil {
            self.onAction!()
        }
    }
}

extension UIButton {
    
    convenience init(_ color: UIColor,
                     _ cornerRadius: CGFloat,
                     _ borderWidth: CGFloat,
                     _ buttonText: String,
                     _ textColor: UIColor) {
        self.init()
        self.layer.borderColor = color.cgColor
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = borderWidth
        self.setTitle(buttonText, for: .normal)
        self.setTitleColor(textColor, for: .normal)
    }
}

extension UIButton {
    func startLoading(loaderImage: UIImage) {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .fixed
        config.background.cornerRadius = 8
        config.baseBackgroundColor = self.configuration?.baseBackgroundColor ?? .systemBlue

        config.image = loaderImage
        config.imagePlacement = .leading
        config.imagePadding = 0
        config.title = nil

        self.configuration = config
        self.isUserInteractionEnabled = false
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 1
        rotation.repeatCount = .infinity
        self.imageView?.layer.add(rotation, forKey: "rotate")
    }

    func stopLoading(title: String?, icon: UIImage?, backgroundColor: UIColor) {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .fixed
        config.background.cornerRadius = 8
        config.baseBackgroundColor = backgroundColor

        config.title = title
        config.image = icon
        config.imagePlacement = .leading
        config.imagePadding = 8

        self.configuration = config
        self.isUserInteractionEnabled = true

        self.imageView?.layer.removeAnimation(forKey: "rotate")
    }
}
