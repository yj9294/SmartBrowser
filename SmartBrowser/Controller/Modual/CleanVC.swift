//
//  CleanVC.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/11.
//

import UIKit
import Lottie

class CleanVC: BaseVC {
    
    var completion: (()->Void)? = nil
    
    var animationTimer: Timer? = nil
    var adTimer: Timer? = nil
    
    init(_ completion: (()->Void)? = nil) {
        self.completion = completion
        super.init(nibName: "CleanVC", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var animationView: AnimationView = {
        let view = AnimationView(name: "clean_animation")
        view.loopMode = .loop
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(animationView, at: 1)
        animationView.play()
        animationView.center = CGPoint(x: view.center.x, y: view.center.y - 150)
        animationView.bounds = self.view.frame
        
        
        if adTimer != nil || animationTimer != nil {
            adTimer?.invalidate()
            animationTimer?.invalidate()
        }
        
        var needShowAD = false
        var maxTime = false
        adTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { timer in
            if GADUtil.share.isLoaded(.interstitial), needShowAD {
                timer.invalidate()
                GADUtil.share.show(.interstitial, from: self) { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self?.completion?()
                        self?.dismiss(animated: true)
                    }
                }
            } else if maxTime {
                timer.invalidate()
                self.dismiss(animated: true)
                self.completion?()
            }
        })
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false, block: { timer in
            timer.invalidate()
            needShowAD = true
        })
        
        
        Timer.scheduledTimer(withTimeInterval: 15.6, repeats: false) { timer in
            timer.invalidate()
            maxTime = true
        }
        
        GADUtil.share.load(.interstitial)
    }
}
