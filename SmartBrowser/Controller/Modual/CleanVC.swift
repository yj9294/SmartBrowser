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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.completion?()
            self.dismiss(animated: true)
        }
    }
}
