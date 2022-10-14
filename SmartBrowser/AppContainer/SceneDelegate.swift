//
//  SceneDelegate.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/9.
//

import UIKit
import FBSDKCoreKit
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    var homeWindow: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        FirebaseApp.configure()
        
        if let url = connectionOptions.urlContexts.first?.url {
            ApplicationDelegate.shared.application(
                    UIApplication.shared,
                    open: url,
                    sourceApplication: nil,
                    annotation: [UIApplication.OpenURLOptionsKey.annotation]
                )
        }
        
        
        self.window?.rootViewController = LaunchVC()
        
        self.homeWindow = UIWindow()
        
        self.homeWindow?.rootViewController = HomeVC()
        
        self.homeWindow?.windowScene = self.window?.windowScene
        
        self.window?.makeKeyAndVisible()
        
        AppSceneDelegate = self
        
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        // gad config
        GADUtil.share.requestRemoteConfig()
        
        if AppEnterbackground {
            FirebaseUtil.logEvent(name: .openHot)
        }
        
        AppEnterbackground = false
        
        // 广告热启动
        if let vc = window?.rootViewController?.presentedViewController {
            vc.dismiss(animated: false) {
                self.window?.makeKeyAndVisible()
                if let launchVC = self.window?.rootViewController as? LaunchVC {
                    launchVC.launching()
                }
            }
        } else if let vc = homeWindow?.rootViewController?.presentedViewController {
            vc.dismiss(animated: false) {
                self.window?.makeKeyAndVisible()
                if let launchVC = self.window?.rootViewController as? LaunchVC {
                    launchVC.launching()
                }
            }
        } else {
            self.window?.makeKeyAndVisible()
            if let launchVC = self.window?.rootViewController as? LaunchVC {
                launchVC.launching()
            }
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        AppEnterbackground = true
        AppEnterbackgrounded = true
    }

}

