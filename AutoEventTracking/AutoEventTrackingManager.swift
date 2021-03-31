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
    private let eventBeginKey = "eventBegin"
    private let eventPauseKey = "eventPause"
    private let eventDurationKey = "eventDuration"
    
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
    
    // 保存需要统计时间相关的事件
    private var trackTimer = [TrackEventType: [String: Any]]()
    
    /// 记录进入后台的还未暂停的事件，进入后台不应该算入事件时长
    private var enterBackgroundTimerEvents: [TrackEventType] = []
    
    /// 用户登录后，用来标识用户
    private var loginId: String? {
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
        
        // 暂停所有事件的时长统计
        trackTimer.forEach { (event, eventTimer) in
            // 是否暂停
            let isPuased = eventTimer[eventPauseKey] as? Bool ?? false
            if !isPuased {
                // 如果没有暂停，记录起来
                enterBackgroundTimerEvents.append(event)
                // 给设置暂停
                trackTimerPause(event: event)
            }
        }
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
        
        // 恢复所有事件的时长统计
        enterBackgroundTimerEvents.forEach { (event) in
            trackTimerResume(event: event)
        }
        
        // 移除所有保存的暂停统计时长事件
        enterBackgroundTimerEvents.removeAll()
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
    
    public func login(withLoginID id: String?) {
        loginId = id
    }
}

// MARK: - Timer
extension AutoEventTrackingManager {
    public func trackTimerStart(event: TrackEventType) {
        // 记录开始时间，采集开机时间，系统启动时间
        trackTimer[event] = [
            eventBeginKey: ProcessInfo.processInfo.systemUptime * 1000
        ]
    }
    
    public func trackTimerEnd(event: TrackEventType, properties: [String: Any]? = nil) {
        guard let eventTimer = trackTimer[event] else {
            track(event: event, properties: properties)
            return
        }
        
        trackTimer[event] = nil
        
        var newProperties: [String: Any] = properties ?? [:]
        
        // 判断事件是否处于暂停状态
        let isPaused = eventTimer[eventPauseKey] as? Bool ?? false
        // 取出暂停时保存的事件时长
        let eventDuration = eventTimer[eventDurationKey] as? Double ?? 0
        if isPaused {
            newProperties["\(propertiesKeyFlag)event_duration"] = eventDuration
        } else {
            // 开始时间
            let beginTime = eventTimer[eventBeginKey] as? Double ?? 0
            let durationTime = ProcessInfo.processInfo.systemUptime * 1000 - beginTime + eventDuration
            newProperties["\(propertiesKeyFlag)event_duration"] = durationTime
        }
        
        // 上报数据
        track(event: event, properties: newProperties)
    }
    
    public func trackTimerPause(event: TrackEventType) {
        // 事件不存在，返回
        guard var eventTimer = trackTimer[event] else {
            return
        }
        
        // 事件已经暂停，直接返回
        if eventTimer[eventPauseKey] as? Bool == .some(true) {
          return
        }
        
        // 保存暂停前统计的时长
        let eventBegin = eventTimer[eventBeginKey] as? Double ?? 0
        // 现在的系统时间 - 开始保存的 + 已经持续的
        let eventDuration = ProcessInfo.processInfo.systemUptime * 1000 - eventBegin + (eventTimer[eventDurationKey] as? Double ?? 0)
        // 重新保存持续事件持续时长
        eventTimer[eventDurationKey] = eventDuration
        
        // 设置暂停标志
        eventTimer[eventPauseKey] = true
        
        trackTimer[event] = eventTimer
    }
    
    public func trackTimerResume(event: TrackEventType) {
        // 事件不存在，或者没有统计暂停，直接返回
        guard var eventTimer = trackTimer[event],
              eventTimer[eventPauseKey] as? Bool == .some(true) else {
            return
        }
        
        // 重置开始时间
        eventTimer[eventBeginKey] = ProcessInfo.processInfo.systemUptime * 1000
        
        // 重置暂停标志
        eventTimer[eventPauseKey] = false
        
        trackTimer[event] = eventTimer
    }
}
