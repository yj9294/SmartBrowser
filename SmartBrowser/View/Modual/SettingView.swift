//
//  SettingView.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/11.
//

import UIKit

class SettingView: BaseView {
    
    var newHandle: (()->Void)? = nil
    var copyHandle: (()->Void)? = nil
    var shareHandle: (()->Void)? = nil
    var rateHandle: (()->Void)? = nil
    var privacyHandle: (()->Void)? = nil
    var termsHandle: (()->Void)? = nil

    @IBAction func newAction() {
        dismiss()
        newHandle?()
    }
    
    @IBAction func copyAction() {
        dismiss()
        copyHandle?()
    }
    
    @IBAction func shareAction() {
        dismiss()
        shareHandle?()
    }
    
    @IBAction func rateAction() {
        dismiss()
        rateHandle?()
    }
    
    @IBAction func termsAction() {
        dismiss()
        termsHandle?()
    }

    @IBAction func privacyAction() {
        dismiss()
        privacyHandle?()
    }
}
