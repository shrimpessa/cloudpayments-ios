//
//  UIImage+Assets.swift
//  sdk
//
//  Created by Sergey Iskhakov on 24.09.2020.
//  Copyright © 2020 Cloudpayments. All rights reserved.
//

import UIKit

extension UIImage {
    
    public class func named(_ name: String) -> UIImage {
        
        let image2 = UIImage.init(named: name, in: Bundle.mainSdk, compatibleWith: nil)
        if image2 != nil {
            return image2!
        }
        return UIImage()
    }
    
    public class var iconDolyame: UIImage {
        return self.named("icon_dolyame_button")
    }
    
    public class var iconDolyameAdditional: UIImage {
        return self.named("icon_dolyame_additional")
    }
    
    public class var iconTPay: UIImage {
        return self.named("ic_tpay")
    }
    
    public class var iconTInstalment: UIImage {
        return self.named("ic_tInstalment")
    }
    
    public class var iconSberPayAdditional: UIImage {
        return self.named("icon_sber_pay_additional")
    }
    
    public class var iconSberPay: UIImage {
        return self.named("icon_sber_pay_button")
    }
    
    public class var iconSbp: UIImage {
        return self.named("icon_sbp_button")
    }
    
    public class var iconSbpAdditional: UIImage {
        return self.named("icon_sbp_button_additional")
    }
    
    public class var iconTpayAdditional: UIImage {
        return self.named("icon_tpay_additional")
    }
    
    public class var iconTInstalmentAdditional: UIImage {
        return self.named("icon_tInstalment_additional")
    }
    
    public class var iconCardAdditional: UIImage {
        return self.named("icon_card_additional")
    }
    
    public class var iconForeignCardAdditional: UIImage {
        return self.named("icon_foreign_card_additional")
    }
    
    public class var iconProgress: UIImage {
        return self.named("ic_progress")
    }
    
    public class var iconSuccess: UIImage {
        return self.named("ic_success")
    }
    
    public class var iconFailed: UIImage {
        return self.named("ic_failed")
    }
    
    public class var iconUnselected: UIImage {
        return self.named("ic_checkbox_unselected")
    }
    
    public class var iconSelected: UIImage {
        return self.named("ic_checkbox_selected")
    }
    
    public class var icn_attention: UIImage {
        return self.named("icn_attention")
    }
    
    public class var icn_sbp_logo: UIImage {
        return self.named("icon_sbp_logo")
    }
    
    public class var icon_not_found_banks: UIImage {
        return self.named("icon_not_found_banks")
    }
    
    public class var iconLogo: UIImage {
        return self.named("footerLogoPayments")
    }
    
    public class var ic_button_logo: UIImage {
        return self.named("ic_button_loader")
    }
    
    public class var iconMethodSberPay: UIImage {
        return self.named("icon_method_sber_pay")
    }
    
    public class var iconMethodDolyame: UIImage {
        return self.named("icon_method_dolyame")
    }
    
    public class var iconForeignCard: UIImage {
        return self.named("icn_foreign_card")
    }
    
    public class var iconDr: UIImage {
        return self.named("icon_dr_button")
    }
    
    public class var iconDrAdditional: UIImage {
        return self.named("icon_dr_additional")
    }
    
}

extension UIImageView {
    
    convenience init(image: UIImage? = nil, contentMode: UIView.ContentMode?) {
            self.init()
            
            if let image = image {
                self.image = image
            }
            
            if let contentMode = contentMode {
                self.contentMode = contentMode
            }
        }

    var colorRenderForImage:UIColor {
        get {return self.tintColor}
        set {
            self.image = self.image?.withRenderingMode(.alwaysTemplate)
            self.tintColor = newValue
        }
    }
}

