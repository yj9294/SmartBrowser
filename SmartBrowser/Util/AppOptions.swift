//
//  AppOptions.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/9.
//

import UIKit

func SLog(_ log: @autoclosure () -> String) {
//#if DEBUG
    NSLog("\(log())")
//#else
//    debugPrint(log())
//#endif
}

var AppSceneDelegate: SceneDelegate? = nil
var AppEnterbackground: Bool = false
var AppEnterbackgrounded: Bool = false
