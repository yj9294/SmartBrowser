//
//  GADUtil.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/13.
//

import UIKit
import GoogleMobileAds
import Firebase

class GADUtil: NSObject {
    static let share = GADUtil()
    override init() {
        super.init()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.ads.forEach {
                $0.loadedArray = $0.loadedArray.filter({ model in
                    return model.loadedDate?.isExpired == false
                })
            }
        }
    }
    
    // 本地记录 配置
    var adConfig: ADConfig? {
        set{
            UserDefaults.standard.setObject(newValue, forKey: .adConfig)
        }
        get {
            UserDefaults.standard.getObject(ADConfig.self, forKey: .adConfig)
        }
    }
    
    // 本地记录 限制次数
    var limit: ADLimit? {
        set{
            UserDefaults.standard.setObject(newValue, forKey: .adLimited)
        }
        get {
            UserDefaults.standard.getObject(ADLimit.self, forKey: .adLimited)
        }
    }
    
    /// 是否超限
    var isADLimited: Bool {
        if limit?.date.isToday == true {
            if (limit?.showTimes ?? 0) >= (adConfig?.showTimes ?? 0) || (limit?.clickTimes ?? 0) >= (adConfig?.clickTimes ?? 0) {
                return true
            }
        }
        return false
    }
    
    /// 是否需要插屏显示间隔
    var isNeedInterstitialShow = false
    
    /// 广告位加载模型
    let ads:[ADLoadModel] = ADPosition.allCases.map { p in
        ADLoadModel(position: p)
    }.filter { m in
        m.position != .all
    }
}

extension GADUtil {
    
    func isLoaded(_ position: ADPosition) -> Bool {
        return self.ads.filter {
            $0.position == position
        }.first?.isLoaded == true
    }
    /// 请求远程配置
    func requestRemoteConfig() {
        // 获取本地配置
        if adConfig == nil {
            let path = Bundle.main.path(forResource: "admob", ofType: "json")
            let url = URL(fileURLWithPath: path!)
            do {
                let data = try Data(contentsOf: url)
                adConfig = try JSONDecoder().decode(ADConfig.self, from: data)
                SLog("[Config] Read local ad config success.")
            } catch let error {
                SLog("[Config] Read local ad config fail.\(error.localizedDescription)")
            }
        }
        
        /// 远程配置
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        remoteConfig.configSettings = settings
        remoteConfig.fetch { [weak remoteConfig] (status, error) -> Void in
            if status == .success {
                SLog("[Config] Config fetcher! ✅")
                remoteConfig?.activate(completion: { _, _ in
                    let keys = remoteConfig?.allKeys(from: .remote)
                    SLog("[Config] config params = \(keys ?? [])")
                    if let remoteAd = remoteConfig?.configValue(forKey: "adConfig").stringValue {
                        // base64 的remote 需要解码
                        let data = Data(base64Encoded: remoteAd) ?? Data()
                        if let remoteADConfig = try? JSONDecoder().decode(ADConfig.self, from: data) {
                            // 需要在主线程
                            DispatchQueue.main.async {
                                self.adConfig = remoteADConfig
                            }
                        } else {
                            SLog("[Config] Config config 'ad_config' is nil or config not json.")
                        }
                    }
                })
            } else {
                SLog("[Config] config not fetcher, error = \(error?.localizedDescription ?? "")")
            }
        }
        
        /// 广告配置是否是当天的
        if limit == nil || limit?.date.isToday != true {
            limit = ADLimit(showTimes: 0, clickTimes: 0, date: Date())
        }
    }
    
    /// 限制
    func add(_ status: ADLimit.Status) {
        if status == .show {
            if isADLimited {
                SLog("[AD] 用戶超限制。")
                self.clean(.all)
                self.close(.all)
                return
            }
            let showTime = limit?.showTimes ?? 0
            limit?.showTimes = showTime + 1
            SLog("[AD] [LIMIT] showTime: \(showTime+1) total: \(adConfig?.showTimes ?? 0)")
        } else  if status == .click {
            let clickTime = limit?.clickTimes ?? 0
            limit?.clickTimes = clickTime + 1
            SLog("[AD] [LIMIT] clickTime: \(clickTime+1) total: \(adConfig?.clickTimes ?? 0)")
            if isADLimited {
                SLog("[AD] 用戶超限制。")
                self.clean(.all)
                self.close(.all)
                return
            }
        }
    }
    
    /// 加载
    func load(_ position: ADPosition, completion: (()->Void)? = nil) {
        let ads = ads.filter{
            $0.position == position
        }
        if let ad = ads.first {
            ad.beginAddWaterFall { isSuccess in
                completion?()
                if isSuccess {
                    switch position {
                    case .native:
                        self.show(position) { ad in
                            NotificationCenter.default.post(name: .nativeUpdate, object: ad)
                        }
                    default:
                        break
                    }
                }
            }
        } else {
            completion?()
        }
    }
    
    /// 展示
    func show(_ position: ADPosition, from vc: UIViewController? = nil , completion: @escaping (ADBaseModel?)->Void) {
        // 超限需要清空广告
        if isADLimited {
            clean(.all)
        }
        let loadAD = ads.filter {
            $0.position == position
        }.first
        switch position {
        case .interstitial:
            /// 有廣告
            if let ad = loadAD?.loadedArray.first as? InterstitialADModel, !AppEnterbackground, !isADLimited {
                ad.impressionHandler = { [weak self, loadAD] in
                    if self?.isNeedInterstitialShow == true {
                        loadAD?.impressionDate = Date()
                    }
                    self?.add(.show)
                    self?.display(position)
                    self?.load(position)
                }
                ad.clickHandler = { [weak self] in
                    self?.add(.click)
                }
                ad.closeHandler = { [weak self] in
                    self?.close(position)
                    if !AppEnterbackground {
                        completion(nil)
                    }
                }
                if !AppEnterbackground {
                    if isNeedInterstitialShow {
                        if loadAD?.isNeedShow == true {
                            ad.present()
                        } else {
                            completion(nil)
                        }
                    } else {
                        ad.present(from: vc)
                    }
                }
            } else {
                completion(nil)
            }
            
        case .native:
            if let ad = loadAD?.loadedArray.first as? NativeADModel, !AppEnterbackground, !isADLimited {
                /// 预加载回来数据 当时已经有显示数据了
                if loadAD?.isDisplay == true {
                    return
                }
                ad.nativeAd?.unregisterAdView()
                ad.nativeAd?.delegate = ad
                ad.impressionHandler = {
                    loadAD?.impressionDate = Date()
                    self.add(.show)
                    self.display(position)
                    self.load(position)
                }
                ad.clickHandler = {
                    self.add(.click)
                }
                // 10秒间隔
                if loadAD?.isNeedShow == true {
                    completion(ad)
                }
            } else {
                /// 预加载回来数据 当时已经有显示数据了 并且没超过限制
                if loadAD?.isDisplay == true, !isADLimited {
                    return
                }
                completion(nil)
            }
        default:
            break
        }
    }
    
    /// 清除缓存 针对loadedArray数组
    func clean(_ position: ADPosition) {
        switch position {
        case .all:
            ads.filter{
                $0.position.isNativeAD
            }.forEach {
                $0.clean()
            }
        default:
            let loadAD = ads.filter{
                $0.position == position
            }.first
            loadAD?.clean()
        }
    }
    
    /// 关闭正在显示的广告（原生，插屏）针对displayArray
    func close(_ position: ADPosition) {
        switch position {
        case .all:
            ads.forEach {
                $0.closeDisplay()
            }
        default:
            ads.filter{
                $0.position == position
            }.first?.closeDisplay()
        }
        if position == .native || position == .all {
            NotificationCenter.default.post(name: .nativeUpdate, object: nil)
        }
    }
    
    /// 展示
    func display(_ position: ADPosition) {
        switch position {
        case .all:
            break
        default:
            ads.filter {
                $0.position == position
            }.first?.display()
        }
    }
}

struct ADConfig: Codable {
    var showTimes: Int?
    var clickTimes: Int?
    var ads: [ADModels?]?
    
    func arrayWith(_ postion: ADPosition) -> [ADModel] {
        guard let ads = ads else {
            return []
        }
        
        guard let models = ads.filter({$0?.key == postion.rawValue}).first as? ADModels, let array = models.value   else {
            return []
        }
        
        return array.sorted(by: {$0.theAdPriority > $1.theAdPriority})
    }
    struct ADModels: Codable {
        var key: String
        var value: [ADModel]?
    }
}

class ADBaseModel: NSObject, Identifiable {
    let id = UUID().uuidString
    /// 廣告加載完成時間
    var loadedDate: Date?
    
    /// 點擊回調
    var clickHandler: (() -> Void)?
    /// 展示回調
    var impressionHandler: (() -> Void)?
    /// 加載完成回調
    var loadedHandler: ((_ result: Bool, _ error: String) -> Void)?
    
    /// 當前廣告model
    var model: ADModel?
    /// 廣告位置
    var position: ADPosition = .all
    
    init(model: ADModel?) {
        super.init()
        self.model = model
    }
}

extension ADBaseModel {
    @objc public func loadAd( completion: @escaping ((_ result: Bool, _ error: String) -> Void)) {
        
    }
    
    @objc public func present(from vc: UIViewController? = nil) {
        
    }
}

struct ADModel: Codable {
    var theAdPriority: Int
    var theAdID: String
}

struct ADLimit: Codable {
    var showTimes: Int
    var clickTimes: Int
    var date: Date
    
    enum Status {
        case show, click
    }
}

enum ADPosition: String, CaseIterable {
    case all, native, interstitial

    var isNativeAD: Bool {
        switch self {
        case .native:
            return true
        default:
            return false
        }
    }
    
    var isInterstitialAd: Bool {
        if self == .all {
            return false
        }
        return !self.isNativeAD
    }
}

class ADLoadModel: NSObject {
    /// 當前廣告位置類型
    var position: ADPosition = .all
    /// 當前正在加載第幾個 ADModel
    var preloadIndex: Int = 0
    /// 是否正在加載中
    var isPreloadingAd = false
    /// 正在加載術組
    var loadingArray: [ADBaseModel] = []
    /// 加載完成
    var loadedArray: [ADBaseModel] = []
    /// 展示
    var displayArray: [ADBaseModel] = []
    
    var isLoaded: Bool = false
    
    var isDisplay: Bool {
        return displayArray.count > 0
    }
    
    /// 该广告位显示广告時間 每次显示更新时间
    var impressionDate = Date(timeIntervalSinceNow: -100)
    
    /// 显示的时间间隔小于 11.2秒
    var isNeedShow: Bool {
        if Date().timeIntervalSince1970 - impressionDate.timeIntervalSince1970 < 10 {
            SLog("[AD] (\(position)) 10s 刷新间隔不代表展示，有可能是请求返回")
            return false
        }
        return true
    }
        
    init(position: ADPosition) {
        super.init()
        self.position = position
    }
}

extension ADLoadModel {
    func beginAddWaterFall(callback: ((_ isSuccess: Bool) -> Void)? = nil) {
        isLoaded = false
        if isPreloadingAd == false, loadedArray.count == 0 {
            SLog("[AD] (\(position.rawValue) start to prepareLoad.--------------------")
            if let array: [ADModel] = GADUtil.share.adConfig?.arrayWith(position), array.count > 0 {
                preloadIndex = 0
                SLog("[AD] (\(position.rawValue)) start to load array = \(array.count)")
                prepareLoadAd(array: array) { [weak self] isSuccess in
                    self?.isLoaded = true
                    callback?(isSuccess)
                }
            } else {
                isPreloadingAd = false
                SLog("[AD] (\(position.rawValue)) no configer.")
            }
        } else if loadedArray.count > 0 {
            isLoaded = true
            callback?(true)
            SLog("[AD] (\(position.rawValue)) loaded ad.")
        } else if isPreloadingAd == true {
            SLog("[AD] (\(position.rawValue)) loading ad.")
        }
    }
    
    func prepareLoadAd(array: [ADModel], callback: ((_ isSuccess: Bool) -> Void)?) {
        if array.count == 0 || preloadIndex >= array.count {
            SLog("[AD] (\(position.rawValue)) prepare Load Ad Failed, no more avaliable config.")
            isPreloadingAd = false
            return
        }
        SLog("[AD] (\(position)) prepareLoaded.")
        if GADUtil.share.isADLimited {
            SLog("[AD] (\(position.rawValue)) 用戶超限制。")
            callback?(false)
            return
        }
        if loadedArray.count > 0 {
            SLog("[AD] (\(position.rawValue)) 已經加載完成。")
            callback?(false)
            return
        }
        if isPreloadingAd, preloadIndex == 0 {
            SLog("[AD] (\(position.rawValue)) 正在加載中.")
            callback?(false)
            return
        }
        
        isPreloadingAd = true
        var ad: ADBaseModel? = nil
        if position.isNativeAD {
            ad = NativeADModel(model: array[preloadIndex])
        } else if position.isInterstitialAd {
            ad = InterstitialADModel(model: array[preloadIndex])
        }
        ad?.position = position
        ad?.loadAd { [weak ad] result, error in
            guard let ad = ad else { return }
            /// 刪除loading 中的ad
            self.loadingArray = self.loadingArray.filter({ loadingAd in
                return ad.id != loadingAd.id
            })
            
            /// 成功
            if result {
                self.isPreloadingAd = false
                self.loadedArray.append(ad)
                callback?(true)
                return
            }
            
            if self.loadingArray.count == 0 {
                let next = self.preloadIndex + 1
                if next < array.count {
                    SLog("[AD] (\(self.position.rawValue)) Load Ad Failed: try reload at index: \(next).")
                    self.preloadIndex = next
                    self.prepareLoadAd(array: array, callback: callback)
                } else {
                    SLog("[AD] (\(self.position.rawValue)) prepare Load Ad Failed: no more avaliable config.")
                    self.isPreloadingAd = false
                    callback?(false)
                }
            }
            
        }
        if let ad = ad {
            loadingArray.append(ad)
        }
    }
    
    func display() {
        self.displayArray = self.loadedArray
        self.loadedArray = []
    }
    
    func closeDisplay() {
        self.displayArray = []
    }
    
    func clean() {
        self.displayArray = []
        self.loadedArray = []
        self.loadingArray = []
    }
}

extension Date {
    var isExpired: Bool {
        Date().timeIntervalSince1970 - self.timeIntervalSince1970 > 3000
    }
    
    var isToday: Bool {
        let diff = Calendar.current.dateComponents([.day], from: self, to: Date())
        if diff.day == 0 {
            return true
        } else {
            return false
        }
    }
}


class InterstitialADModel: ADBaseModel {
    /// 關閉回調
    var closeHandler: (() -> Void)?
    var autoCloseHandler: (()->Void)?
    /// 異常回調 點擊了兩次
    var clickTwiceHandler: (() -> Void)?
    
    /// 是否點擊過，用於拉黑用戶
    var isClicked: Bool = false
    
    /// 插屏廣告
    var interstitialAd: GADInterstitialAd?
    
    deinit {
        SLog("[Memory] (\(position.rawValue)) \(self) 💧💧💧.")
    }
}

extension InterstitialADModel {
    public override func loadAd(completion: ((_ result: Bool, _ error: String) -> Void)?) {
        loadedHandler = completion
        loadedDate = nil
        GADInterstitialAd.load(withAdUnitID: model?.theAdID ?? "", request: GADRequest()) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                SLog("[AD] (\(self.position.rawValue)) load ad FAILED for id \(self.model?.theAdID ?? "invalid id")")
                self.loadedHandler?(false, error.localizedDescription)
                return
            }
            SLog("[AD] (\(self.position.rawValue)) load ad SUCCESSFUL for id \(self.model?.theAdID ?? "invalid id") ✅✅✅✅")
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.loadedDate = Date()
            self.loadedHandler?(true, "")
        }
    }
    
    override func present(from vc: UIViewController? = nil) {
        if let vc = vc {
            interstitialAd?.present(fromRootViewController: vc)
        } else if let keyWindow = UIApplication.shared.windows.filter({$0.isKeyWindow}).first, let rootVC = keyWindow.rootViewController {
            interstitialAd?.present(fromRootViewController: rootVC)
        }
    }
}

extension InterstitialADModel : GADFullScreenContentDelegate {
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        loadedDate = Date()
        impressionHandler?()
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        SLog("[AD] (\(self.position.rawValue)) didFailToPresentFullScreenContentWithError ad FAILED for id \(self.model?.theAdID ?? "invalid id")")
        if AppEnterbackground {
            closeHandler?()
        }
    }
    
    func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        closeHandler?()
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        clickHandler?()
    }
}

class NativeADModel: ADBaseModel {
    /// 廣告加載器
    var loader: GADAdLoader?
    /// 原生廣告
    var nativeAd: GADNativeAd?
    
    deinit {
        SLog("[Memory] (\(position.rawValue)) \(self) 💧💧💧.")
    }
}

extension NativeADModel {
    public override func loadAd(completion: ((_ result: Bool, _ error: String) -> Void)?) {
        loadedDate = nil
        loadedHandler = completion
        loader = GADAdLoader(adUnitID: model?.theAdID ?? "", rootViewController: nil, adTypes: [.native], options: nil)
        loader?.delegate = self
        loader?.load(GADRequest())
    }
    
    public func unregisterAdView() {
        nativeAd?.unregisterAdView()
    }
}

extension NativeADModel: GADAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        SLog("[AD] (\(position.rawValue)) load ad FAILED for id \(model?.theAdID ?? "invalid id")")
        loadedHandler?(false, error.localizedDescription)
    }
}

extension NativeADModel: GADNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        SLog("[AD] (\(position.rawValue)) load ad SUCCESSFUL for id \(model?.theAdID ?? "invalid id") ✅✅✅✅")
        self.nativeAd = nativeAd
        loadedDate = Date()
        loadedHandler?(true, "")
    }
}

extension NativeADModel: GADNativeAdDelegate {
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        clickHandler?()
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        impressionHandler?()
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
    }
}

extension Notification.Name {
    static let nativeUpdate = Notification.Name(rawValue: "homeNativeUpdate")
}

extension String {
    static let adConfig = "adConfig"
    static let adLimited = "adLimited"
    static let adUnAvaliableDate = "adUnAvaliableDate"
}
