//
//  HomeVC.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/9.
//

import UIKit
import WebKit
import MobileCoreServices
import AppTrackingTransparency

class HomeVC: BaseVC {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var searchPlaceholderLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var tabButton: UIButton!
    
    var startDate: Date? = nil
    
    var webView: WKWebView {
        BrowserUtil.shared.webItem.webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registeNotification()
        ATTrackingManager.requestTrackingAuthorization { status in
            debugPrint(status)
        }
    }
    
    override func viewDidLayoutSubviews() {
        webView.frame = centerView.frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseUtil.logEvent(name: .homeShow)
        if BrowserUtil.shared.webItem.isNavigation {
            FirebaseUtil.logEvent(name: .navigaShow)
        }
        tabButton.setTitle("\(BrowserUtil.shared.webItems.count)", for: .normal)
        tabButton.setTitleColor(.black, for: .normal)
        view.subviews.forEach {
            if $0 is WKWebView {
                $0.removeFromSuperview()
            }
        }
        if !BrowserUtil.shared.webItem.isNavigation, webView.url != nil {
            view.addSubview(webView)
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), context: nil)
        }
        setupUI()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webViewDisappear()
    }
    
    func webViewDisappear() {
        if !BrowserUtil.shared.webItem.isNavigation {
            webView.removeFromSuperview()
            webView.navigationDelegate = nil
            webView.uiDelegate = nil
            if webView.observationInfo != nil {
                webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
                webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
            }
        }
    }
    
    
    func registeNotification() {
        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] _ in
            self?.keyboardWillShow()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.keyboardWillHidden()
        }
        
        self.searchField.delegate = self
    }
    
    func setupUI() {
        tabButton.layer.cornerRadius = 2
        tabButton.layer.masksToBounds = true
        tabButton.layer.borderWidth = 1
        tabButton.layer.borderColor = UIColor.black.cgColor
        
        backButton.isEnabled = webView.canGoBack
        nextButton.isEnabled = webView.canGoForward
        
        progressView.isHidden = !webView.isLoading
        searchField.text = webView.url?.absoluteString ?? ""
        searchButton.isSelected = webView.isLoading
        searchPlaceholderLabel.isHidden = searchField.text != ""
        
        
        tabButton.setTitle("\(BrowserUtil.shared.webItems.count)", for: .normal)
        
    }
    
    func searching() {
        view.endEditing(true)
        guard let url = searchField.text, url.count != 0 else {
            self.alert("Please enter your search content.")
            return
        }
        searchButton.isSelected = !searchButton.isSelected
        progressView.isHidden = false
        searchPlaceholderLabel.isHidden = searchField.text?.count != 0
        // 加载
        BrowserUtil.shared.webItem.loadUrl(url, from: self)
        FirebaseUtil.logEvent(name: .webStart)
        startDate = Date()
    }
    
    func stopSearch() {
        searchField.text = ""
        keyboardWillHidden()
        view.endEditing(true)
        searchButton.isSelected = !searchButton.isSelected
        progressView.isHidden = true
        // 停止加载
        BrowserUtil.shared.webItem.stopLoad()
    }

}

extension HomeVC {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // url重定向
        if keyPath == #keyPath(WKWebView.url) {
            searchField.text = webView.url?.absoluteString
            searchPlaceholderLabel.isHidden = searchField.text?.count != 0
        }
        
        // 进度
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            let progress: Float = Float(webView.estimatedProgress)
            debugPrint(progress)
            searchButton.isSelected = true
            UIView.animate(withDuration: 0.25) {
                self.progressView.progress = progress
            }
            
            // 加载完成
            if progress == 1.0 {
                progressView.isHidden = true
                progressView.progress = 0.0
                searchButton.isSelected = false
                let time = Date().timeIntervalSince1970 - startDate!.timeIntervalSince1970
                FirebaseUtil.logEvent(name: .webSuccess, params: ["lig": "\(ceil(time))"])
            } else {
                progressView.isHidden = false
            }
        }
    }
}

extension HomeVC {
    func keyboardWillShow() {
        searchPlaceholderLabel.isHidden = true
    }
    
    func keyboardWillHidden() {
        if searchField.text?.count == 0 {
            searchPlaceholderLabel.isHidden = false
        }
    }
}

extension HomeVC {
    @IBAction func searchOrCancel() {
        if searchButton.isSelected {
            // cancel
            FirebaseUtil.logEvent(name: .cleanClick)
            stopSearch()
        } else {
            // search
            searching()
        }
    }
    
    @IBAction func facebookAction() {
        searchField.text = HomeItem.facebook.url
        FirebaseUtil.logEvent(name: .navigaClick, params: ["lig": HomeItem.facebook.url])
        searching()
    }
    
    @IBAction func googleAction() {
        searchField.text = HomeItem.google.url
        FirebaseUtil.logEvent(name: .navigaClick, params: ["lig": HomeItem.google.url])
        searching()
    }
    
    @IBAction func youtubeAction() {
        searchField.text = HomeItem.youtube.url
        FirebaseUtil.logEvent(name: .navigaClick, params: ["lig": HomeItem.youtube.url])
        searching()
    }
    
    @IBAction func twitterAction() {
        searchField.text = HomeItem.twitter.url
        FirebaseUtil.logEvent(name: .navigaClick, params: ["lig": HomeItem.twitter.url])
        searching()
    }
    
    @IBAction func instagramAction() {
        searchField.text = HomeItem.instagram.url
        FirebaseUtil.logEvent(name: .navigaClick, params: ["lig": HomeItem.instagram.url])
        searching()
    }
    
    @IBAction func amazonAction() {
        searchField.text = HomeItem.amazone.url
        FirebaseUtil.logEvent(name: .navigaClick, params: ["lig": HomeItem.amazone.url])
        searching()
    }
    
    @IBAction func gmailAction() {
        searchField.text = HomeItem.gmail.url
        FirebaseUtil.logEvent(name: .navigaClick, params: ["lig": HomeItem.gmail.url])
        searching()
    }
    
    @IBAction func yahooAction() {
        searchField.text = HomeItem.yahoo.url
        FirebaseUtil.logEvent(name: .navigaClick, params: ["lig": HomeItem.yahoo.url])
        searching()
    }
    
    @IBAction func gobackAction() {
        webView.goBack()
    }
    
    @IBAction func goNextAction() {
        webView.goForward()
    }
    
    @IBAction func cleanAction() {
        let view = CleanAlertView.loadFromNib()
        view.agreeHandle = {
            // agreeen animation
            let vc = CleanVC {
                FirebaseUtil.logEvent(name: .cleanSuccess)
                BrowserUtil.shared.clean(from: self)
                self.setupUI()
                self.alert("Cleaned successfully.")
                FirebaseUtil.logEvent(name: .cleanAlert)
            }
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
        view.present()
    }
    
    @IBAction func tabAction() {
        let vc = TabVC()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @IBAction func settingAction() {
        let view = SettingView.loadFromNib()
        view.present()
        
        view.newHandle = {
            self.webViewDisappear()
            BrowserUtil.shared.add()
            self.setupUI()
            FirebaseUtil.logEvent(name: .tabNew, params: ["lig": "setting"])
        }
        
        view.shareHandle = {
            FirebaseUtil.logEvent(name: .shareClick)
            var url = "https://itunes.apple.com/cn/app/id6443788592"
            if !BrowserUtil.shared.webItem.isNavigation {
                url = self.webView.url?.absoluteString ?? "https://itunes.apple.com/cn/app/id6443788592"
            }
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            self.present(vc, animated: true)
        }
        
        view.copyHandle = {
            FirebaseUtil.logEvent(name: .copyClick)
            if !BrowserUtil.shared.webItem.isNavigation {
                UIPasteboard.general.setValue(self.webView.url?.absoluteString ?? "", forPasteboardType: kUTTypePlainText as String)
                self.alert("Copy successfully.")
            } else {
                UIPasteboard.general.setValue("", forPasteboardType: kUTTypePlainText as String)
                self.alert("Copy successfully.")
            }
        }
        
        view.rateHandle = {
            let url = URL(string: "https://itunes.apple.com/cn/app/id6443788592")
            if let url = url {
                UIApplication.shared.open(url)
            }
        }
        
        view.privacyHandle = {
            let vc = PrivacyVC(.privacy)
            let navigation = UINavigationController(rootViewController: vc)
            navigation.modalPresentationStyle = .fullScreen
            self.present(navigation, animated: true)
        }
        
        view.termsHandle = {
            let vc = PrivacyVC(.terms)
            let navigation = UINavigationController(rootViewController: vc)
            navigation.modalPresentationStyle = .fullScreen
            self.present(navigation, animated: true)
        }
    }
}

extension HomeVC: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searching()
        if let text = searchField.text {
            FirebaseUtil.logEvent(name: .navigaSearch, params: ["lig": text])
        }
        return true
    }
}

extension HomeVC: WKUIDelegate, WKNavigationDelegate {
    /// 跳转链接前是否允许请求url
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        self.backButton.isEnabled = webView.canGoBack
        self.nextButton.isEnabled = webView.canGoForward
        return .allow
    }
    
    /// 响应后是否跳转
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        self.backButton.isEnabled = webView.canGoBack
        self.nextButton.isEnabled = webView.canGoForward
        return .allow
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        FirebaseUtil.logEvent(name: .webStart)
        /// 打开新的窗口
        self.backButton.isEnabled = webView.canGoBack
        self.nextButton.isEnabled = webView.canGoForward

        webView.load(navigationAction.request)
        return nil
    }
}

enum HomeItem {
    case facebook, google, youtube, twitter, instagram, amazone, gmail, yahoo
    var url: String {
        return "https://www.\(self).com"
    }
}
