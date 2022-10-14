//
//  LaunchVC.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/9.
//

import UIKit

class LaunchVC: BaseVC {
    
    @IBOutlet weak var progressView: UIProgressView!
    
    var launchTimer: Timer? = nil
    var adTimer: Timer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseUtil.logProperty(name: .local)
        FirebaseUtil.logEvent(name: .open)
        FirebaseUtil.logEvent(name: .openCold)
    }
    
    func launching() {
        var progress = 0.0
        var duration = 2.5 / 0.6
        var needShowAD = false
        if launchTimer != nil || adTimer != nil {
            launchTimer?.invalidate()
            adTimer?.invalidate()
        }
        
        
        launchTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self  = self else { return }
            let ivar =  0.01 / duration
            progress += ivar
            if progress < 1.0 {
                self.progressView.progress = Float(progress)
            } else {
                timer.invalidate()
                GADUtil.share.show(.interstitial) { _ in
                    self.goHomeVC()
                }
            }
            
            if GADUtil.share.isLoaded(.interstitial), needShowAD {
                duration = 1.0
            }
        }
        
        adTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { timer in
            timer.invalidate()
            duration = 15.6 + 2.5
            needShowAD = true
        }
        
        GADUtil.share.load(.interstitial)
        GADUtil.share.load(.native)
    }
    
    func goHomeVC() {
        // update the app window to display home controller
        AppSceneDelegate?.homeWindow?.makeKeyAndVisible()
        
        // hot launch and the home vc is not presented viewcontroller
        if AppEnterbackgrounded, AppSceneDelegate?.homeWindow?.rootViewController?.presentedViewController == nil {
            
            // update the home vc's willApear flag to dispaly native ad
            if let vc = AppSceneDelegate?.homeWindow?.rootViewController as? HomeVC {
                vc.willApear = true
                // hot launhc to load the native ad in home vc
                GADUtil.share.load(.native)
            }
            
            // app log event
            FirebaseUtil.logEvent(name: .homeShow)
            if BrowserUtil.shared.webItem.isNavigation {
                FirebaseUtil.logEvent(name: .navigaShow)
            }
        }
    }

}
