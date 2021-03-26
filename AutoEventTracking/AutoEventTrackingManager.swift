//
//  AutoEventTrackingManager.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/8.
//

import UIKit
import AdSupport
//#if swift(>=5)
//import AppTrackingTransparency //适配iOS14
//#endif

public protocol AutoEventTrackingConfigable {
    var propertiesKeyFlag: String { get }
}

extension AutoEventTrackingConfigable {
    public var propertiesKeyFlag: String {
        "$"
    }
}

public class AutoEventTrackingManager: NSObject, AutoEventTrackingConfigable {
    public static let shared = AutoEventTrackingManager()
    private let viewControllerBlackListFileName = "viewControllerBlackList"
    private let loginIdKey = "loginId"
    private let anonymousIdKey = "anonymousId"
    
    /// 公共属性部分，默认采集
    public var commonProperties: [String: Any] = [:]
    /// 控制器页面黑名单，黑名单里面的控制器类型不自动埋点
    public var viewControllerBlackList = Set<String>()
    /// 控制是否在 DEBUG 模式下打印日志
    public var isPrintDubugLog = true
    
    /// 标识 app 是否收到即将失去激活的通知
    private var isAppWillResignActive = false
    
    /// 标识 app 是被后台模式启动的
    private var isAppStartBackground = false
    
    private var keyChain = Keychain()
    
    /// 用户登录后，用来标识用户
    public var loginId: String? {
        didSet {
            UserDefaults.standard.setValue(loginId, forKey: loginIdKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// 用户未登录前标识用户的 ID
    private var anonymousId: String?

    private override init() {
        super.init()
        self.commonProperties = defalutProperties
        self.isAppStartBackground = UIApplication.shared.backgroundTimeRemaining != UIApplication.backgroundFetchIntervalNever
        loginId = UserDefaults.standard.string(forKey: loginIdKey)
        anonymousId = getAnonymousId()
        
        // 加载控制器埋点黑名单
        loadViewControllerBlackList()
        
        setupListeners()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension AutoEventTrackingManager {
    private var defalutProperties: [String: Any] {
        let properties: [String: Any]  = [
            "\(propertiesKeyFlag)os": "iOS",
            "\(propertiesKeyFlag)os_version": UIDevice.current.systemVersion,
            "\(propertiesKeyFlag)os_name": UIDevice.current.systemName,
            "\(propertiesKeyFlag)os_model": UIDevice.current.model,
            "\(propertiesKeyFlag)app_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            "\(propertiesKeyFlag)app_buildNumber": Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "",
            "\(propertiesKeyFlag)app_displayName": Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "",

        ]
        
        return properties
    }
    
    private func setupListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishLaunchingNotification), name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    private func loadViewControllerBlackList() {
        guard let path = Bundle.init(for: Self.self).path(forResource: viewControllerBlackListFileName, ofType: "plist"),
              let array = (NSArray(contentsOfFile: path) as? Array<String>) else { return }

        self.viewControllerBlackList = Set(array)
    }
}

// MARK: - eventResponse
extension AutoEventTrackingManager {
    @objc private func didEnterBackgroundNotification() {
        // 还原标识位
        isAppWillResignActive = false
        
        track(application: TrackEventType.Application.end)
    }
    
    @objc private func willResignActiveNotification() {
        isAppWillResignActive = true
    }
    
    @objc private func didBecomeActiveNotification() {
        // 上下拉通知栏或控制中心时，会调用 didBecomeActiveNotification 导致，埋点时机不准，需要屏蔽掉这种情况
        if isAppWillResignActive {
            isAppWillResignActive = false
            return
        }
        
        // 还原
        isAppStartBackground = false
        track(application: TrackEventType.Application.start(isBackground: false))
    }
    
    @objc private func didFinishLaunchingNotification() {
        // App 在后台运行
        if isAppStartBackground {
            track(application: TrackEventType.Application.start(isBackground: true), properties: ["\(propertiesKeyFlag)App_state": "Background"])
        }
    }
}

extension AutoEventTrackingManager {
    private func track(event: TrackEventType, properties: [String: Any]? = nil) {
        var eventInfo = [String: Any]()
        eventInfo["event"] = event.name
        eventInfo["time"] = Date().timeIntervalSince1970 * 1000
        
        var eventProperties = self.commonProperties
        // 合并两个字典
        if let tempProperties = properties {
            eventProperties.merge(tempProperties, uniquingKeysWith: { $1 })
        }
        
        eventInfo["user_id"] = loginId ?? anonymousId
        
        eventInfo["properties"] = eventProperties
        
        printEvent(eventInfo)
    }
    
    private func printEvent(_ event: [String: Any]) {
        if !isPrintDubugLog {
            return
        }
        
        #if DEBUG
        let result = event.aet.jsonString(prettify: true) ?? ""
        print("\n---------------- ✨✨✨✨✨ 全埋点采集成功 ✨✨✨✨✨ ------------ \n\(result)\n---------------- ✨✨✨✨✨ 全埋点采集成功 ✨✨✨✨✨ ------------ \n")
        #endif
    }
    
    private func save(anonymousId: String) {
        UserDefaults.standard.setValue(anonymousId, forKey: anonymousIdKey)
        UserDefaults.standard.synchronize()
        
        // 保存到 keyChain
        keyChain[anonymousIdKey] = anonymousId
    }
    
    private func getAnonymousId() -> String {
        if let wrapAnonymousId = anonymousId {
            return wrapAnonymousId
        }
        
        if let wrapAnonymousId = UserDefaults.standard.string(forKey: anonymousIdKey) {
            return wrapAnonymousId
        }
        
        // keyChain
        if let wrapAnonymousId = keyChain[anonymousIdKey] {
            return wrapAnonymousId
        }
        
        // IDFA > IDFV > UUID
//        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
//        var isLimitAdTracking = true
//
//        if #available(iOS 14, *) {
//            isLimitAdTracking = ATTrackingManager.trackingAuthorizationStatus ==  .authorized
//        } else {
//            isLimitAdTracking = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
//        }
//
//        if idfa.count > 0, isLimitAdTracking {
//            save(anonymousId: idfa)
//            return idfa
//        }
        
        let idfv = UIDevice.current.identifierForVendor?.uuidString
        if let wrapIdfv = idfv {
            save(anonymousId: wrapIdfv)
            return wrapIdfv
        }
        
        // 保存起来
        save(anonymousId: UUID().uuidString)
        
        return UUID().uuidString
    }
}

extension AutoEventTrackingManager {
    public func track(application event: TrackEventType.Application, properties: [String: Any]? = nil) {
        track(event: TrackEventType.application(event), properties: properties)
    }
    
    public func track(viewController event: TrackEventType.ViewController, properties: [String: Any]? = nil) {
        track(event: TrackEventType.viewController(event), properties: properties)
    }
    
    public func track(view event: TrackEventType.View, properties: [String: Any]? = nil) {
        track(event: TrackEventType.view(event), properties: properties)
    }
    
    public func track(gesture event: TrackEventType.Gesture, properties: [String: Any]? = nil) {
        track(event: TrackEventType.gesture(event), properties: properties)
    }
}
