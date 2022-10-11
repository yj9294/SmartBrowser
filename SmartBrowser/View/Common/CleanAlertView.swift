//
//  CleanAlertView.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/9.
//

import UIKit

class CleanAlertView: BaseView {
    var agreeHandle: (()->Void)? = nil
    
    @IBAction func agreeAction() {
        dismiss()
        agreeHandle?()
    }
}
