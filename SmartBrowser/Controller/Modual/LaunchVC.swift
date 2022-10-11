//
//  LaunchVC.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/9.
//

import UIKit

class LaunchVC: BaseVC {
    
    @IBOutlet weak var progressView: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseUtil.logProperty(name: .local)
        FirebaseUtil.logEvent(name: .open)
        FirebaseUtil.logEvent(name: .openCold)
    }
    
    func launching() {
        var progress = 0.0
        let duration = 2.5
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self  = self else { return }
            let ivar =  0.01 / duration
            progress += ivar
            if progress < 1.0 {
                self.progressView.progress = Float(progress)
            } else {
                timer.invalidate()
                AppSceneDelegate?.homeWindow?.makeKeyAndVisible()
                if AppEnterbackgrounded, AppSceneDelegate?.homeWindow?.rootViewController?.presentedViewController == nil {
                    FirebaseUtil.logEvent(name: .homeShow)
                    if BrowserUtil.shared.webItem.isNavigation {
                        FirebaseUtil.logEvent(name: .navigaShow)
                    }
                }
            }
        }
    }

}
