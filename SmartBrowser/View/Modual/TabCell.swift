//
//  TabCell.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/9.
//

import UIKit
import WebKit

class TabCell: UICollectionViewCell {
    
    @IBOutlet weak var navigationLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var shadowView: UIView!
    
    var deleteHandle: (()->Void)? = nil
    
    var item: WebViewItem? = nil {
        didSet {
            self.layer.masksToBounds = true
            if item?.isSelect == true {
                contentView.layer.borderColor = UIColor.blue.cgColor
                contentView.layer.borderWidth = 2
                contentView.layer.cornerRadius = 12
                contentView.layer.masksToBounds = true
                
            } else {
                contentView.layer.borderColor = UIColor.gray.cgColor
                contentView.layer.borderWidth = 1
                contentView.layer.cornerRadius = 12
                contentView.layer.masksToBounds = true
            }
            
            self.subviews.forEach {
                if $0 is WKWebView {
                    $0.removeFromSuperview()
                }
            }

            if let webView = item?.webView, item?.isNavigation == false{
                navigationLabel.isHidden = true
                self.insertSubview(webView, at: 0)
            } else {
                navigationLabel.isHidden = false
            }
            
            if BrowserUtil.shared.webItems.count == 1 {
                closeButton.isHidden = true
            } else {
                closeButton.isHidden = false
            }
        }
    }
    
    override func layoutSubviews() {
        if let webView = item?.webView {
            webView.frame = self.bounds
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func deleteAction() {
        deleteHandle?()
    }

}
