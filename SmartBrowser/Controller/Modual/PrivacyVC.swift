//
//  PrivacyVC.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/11.
//

import UIKit

class PrivacyVC: BaseVC {
    
    enum Html {
        case privacy, terms
    }
    
    let item: Html
    
    init(_ item: Html) {
        self.item = item
        super.init(nibName: "PrivacyVC", bundle: nil)
        self.title = item == .privacy ? "Privacy Policy" : "Terms of Users"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "common_back"), style: .plain, target: self, action: #selector(back))
        
        textView.text = item == .privacy ? """
Your privacy is important to us. We value our users' privacy and work hard to protect it. Our goal is to create a secure and accessible service for faster Internet browsing. When you use our services, you trust us to provide your information. We understand this is a significant responsibility and work hard to protect your information and keep you in control.



1) Collection of information

The data we collect depends on the context in which you interact with us, the choices you make (including your privacy settings), and the products and features you use. The data we collect may include SDK/API/JS code version, browser, internet service provider, IP address, platform, timestamp, app identifier, app version, app distribution channel, unique device identifier, advertising identifier ( IDFA), Android Advertiser Identifier, Network Card (MAC) Address and International Mobile Equipment Identity (IMEI) Device Model, Endpoint Manufacturer, Endpoint Device OS Version, Session Start/Stop Time, Language Location, Time Zone and Network Status ( WiFi, etc.) etc.



Use  of data

Smart Browser uses the collected data for various purposes:

To provide and maintain our services

Notify you about changes to our services

To allow you to participate in interactive features of our Services when you choose

Provide customer support

To collect analytics or valuable information so that we can improve our services

To monitor the usage of our services

Detect, prevent and resolve technical issues



Data Security

The security of your data is important to us, but remember that no method of transmission over the Internet or method of electronic storage is 100% secure. While we endeavour to use commercially acceptable means to protect your personal data, we cannot guarantee its absolute security.



Changes to this Privacy Policy

We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.

We will notify you by email and/or a prominent notice on our Services and update the "Last Updated" date at the top of this Privacy Policy before the changes become effective.

You are advised to periodically review this Privacy Policy for any changes. Changes to this Privacy Policy will be effective as soon as they are posted on this page.



Contact  us

If you have any questions about this Privacy Policy, you can contact us
""" : """
The following terms and conditions apply to your free download of our Smart Browser applications ("Apps"). By downloading or using the app, these terms will automatically apply to you - so you should make sure you read them carefully before using the app.



You are not allowed to do the following:

You may not copy or modify the app, any part of the app, or our trademarks in any way.

You may not attempt to extract the source code of the Application, nor attempt to translate the Application into other languages ​​or make derivative versions.

You don't jailbreak or root your phone.

You may not use technology to attack our application.



The app does use third party services that state their own terms and conditions.

Links to terms and conditions of third-party service providers used by the app

Google play: https://policies.google.com/privacy

Admob: https://policies.google.com/privacy

Google analytics for Firebase: https://firebase.google.com/policies/analytics

Facebook: https://www.facebook.com/policy.php





Smart Browser will not be responsible for certain things. Some features of the app will require an active internet connection for the app. The connection can be Wi-Fi or provided by your mobile network provider, but if you don't have access to Wi-Fi and you don't have any data allowance left.



Smart Browser apps is committed to making sure that apps are as useful and efficient as possible. Therefore, we reserve the right to make changes or changes to the app at any time for any reason.



Changes to these terms

I may update our terms and conditions from time to time. Therefore, it is recommended that you periodically check this page for any changes. I will notify you of any changes by posting the new terms and conditions on this page.
"""
    }

}

extension PrivacyVC {
    @objc func back() {
        self.dismiss(animated: true)
    }
}
