//
//  BaseView.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/9.
//

import UIKit

class BaseView: UIView,NibLoadable {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    @IBAction func dismiss() {
        UIView.animate(withDuration: 0.25) {
            self.alpha = 0
        } completion: { isSuccess in
            if isSuccess {
                self.removeFromSuperview()
            }
        }
    }
    
    func present(){
        if let window = AppSceneDelegate?.homeWindow {
            window.addSubview(self)
            self.frame = window.bounds
            self.alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1
            }
        }
    }
}
