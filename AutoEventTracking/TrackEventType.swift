//
//  TrackEventType.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/9.
//

import UIKit

/// 所有埋点事件类型
public enum TrackEventType: Hashable {
    public static func == (lhs: TrackEventType, rhs: TrackEventType) -> Bool {
        return lhs.name == rhs.name
    }
    
    /// 应用程序
    public enum Application {
        /// 启动，是否是用户主动启动还是，系统后台系统
        case start(isBackground: Bool)
        /// 结束，进入后台
        case end
    }
    
    /// 控制器，页面
    public enum ViewController {
        /// 曝光
        case expose(UIViewController)
    }
    
    public enum View {
        /// 点击，按钮等点击
        case click
        /// 切换，UISwitch 开关等控件
        case `switch`
        /// UISlider 等滑动控件
        case slide
        /// tableView 或者 CollectionView  didSelect  事件
        case didSelect(view: UIScrollView?, indexPath: IndexPath?)
    }
    
    /// 手势
    public enum Gesture {
        /// 点击手势
        case tap
        /// 长按手势
        case longPress
    }
    
    /// 异常
    public enum Exception {
         
    }
    
    case application(Application)
    case viewController(ViewController)
    case view(View)
    case gesture(Gesture)
    case exception(Exception)
}

extension TrackEventType {
    var name: String {
        switch self {
        case let .application(application):
            return application.name
        case let .viewController(viewController):
            return viewController.name
        case let .view(view):
            return view.name
        case let .gesture(gesture):
            return gesture.name
        case let .exception(exception):
            return exception.name
        }
    }
}

extension TrackEventType.Application: Hashable {
    var name: String {
        let flagString = AutoEventTrackingManager.shared.propertiesKeyFlag
        
        switch self {
        case let .start(isBackground):
            return isBackground ? "\(flagString)ApplicationStartByBackground" : "ApplicationStart"
        case .end:
            return "ApplicationEnd"
        }
    }
}

extension TrackEventType.ViewController: Hashable {
    var name: String {
        let flagString = AutoEventTrackingManager.shared.propertiesKeyFlag
        
        switch self {
        case .expose:
            return "\(flagString)ViewControllerExpose"
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .expose(vc):
            vc.hash(into: &hasher)
        }
    }
}

extension TrackEventType.View: Hashable {
    var name: String {
        let flagString = AutoEventTrackingManager.shared.propertiesKeyFlag
        
        switch self {
        case .click:
            return "\(flagString)ViewClick"
        case .slide:
            return "\(flagString)ViewSlide"
        case .switch:
            return "\(flagString)ViewSwitch"
        case .didSelect:
            return "\(flagString)ViewDidSelect"
        }
    }
}

extension TrackEventType.Gesture: Hashable {
    var name: String {
        let flagString = AutoEventTrackingManager.shared.propertiesKeyFlag
        
        switch self {
        case .tap:
            return "\(flagString)GestureTap"
        case .longPress:
            return "\(flagString)GestureLongPress"
        }
    }
}

extension TrackEventType.Exception: Hashable {
    var name: String {
        let flagString = AutoEventTrackingManager.shared.propertiesKeyFlag
        
        switch self {
        default:
            return "\(flagString)"
        }
    }
}
