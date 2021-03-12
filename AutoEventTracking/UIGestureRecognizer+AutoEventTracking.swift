//
//  geture.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/11.
//

import UIKit


extension UIGestureRecognizer {
    
    @objc public static func UIGestureRecognizerSwiftLoad() {
        // 通过 @selector 获得被替换和替换方法的 SEL，作为 Hook:hookClass:fromeSelector:toSelector 的参数传入
        
        // hook init(target:action:) 方法
        let fromSelectorInit = #selector(self.init(target:action:))
        let toSelectorInit = #selector(hook_init(target:action:))
        Hook.hook(classObject: Self.self, fromSelector: fromSelectorInit, toSelector: toSelectorInit)
        
        // hook addTarget(_:action:) 方法
        let fromSelectorAddTarget = #selector(addTarget(_:action:))
        let toSelectorAddTarget = #selector(hook_addTarget(_:action:))
        Hook.hook(classObject: Self.self, fromSelector: fromSelectorAddTarget, toSelector: toSelectorAddTarget)
    }
}

extension UIGestureRecognizer {
    @objc private func hook_init(target: Any?, action: Selector?) {
        // 调用原方法
        hook_init(target: target, action: action)
        
        // 插入要执行的代码
        insertToInit(target: target, action: action)
    }
    
    @objc private func hook_addTarget(_ target: Any, action: Selector) {
        // 调用原方法
        hook_addTarget(target, action: action)
        
        // 插入要执行的代码
        insertToAddTarget(target, action: action)
    }
    
    private func insertToInit(target: Any?, action: Selector?) {
        // 添加
        if let wrapTarget = target, let wrapAction = action {
            addTarget(wrapTarget, action: wrapAction)
        }
    }
    
    private func insertToAddTarget(_ target: Any, action: Selector)  {
        // 采集手势事件
        hook_addTarget(self, action: #selector(trackGestureAction(sender:)))
    }
    
    @objc private func trackGestureAction(sender: UIGestureRecognizer) {
        guard let view = sender.view as? TrackViewPropertyType,
              sender.state == .ended else {
            return
        }

        var properties = [String: Any]()
        properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewType"] = NSStringFromClass(view.viewType)

        if let trackViewText = view.trackText {
            properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewText"] = trackViewText
        }
        if let trackViewController = view.trackViewController {
            properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewController"] = NSStringFromClass(type(of: trackViewController))
        }
        if let trackViewControllerTitle = view.trackViewController?.trackTitle {
            properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewControllerTitle"] = trackViewControllerTitle
        }
        
        // 区分不同的手势事件
        if !((sender as? UITapGestureRecognizer) == .some(nil)) {
            AutoEventTrackingManager.shared.track(gestureEvent: TrackEventType.Gesture.tap, properties: properties)
        } else if !((sender as? UILongPressGestureRecognizer) == .some(nil)) {
            AutoEventTrackingManager.shared.track(gestureEvent: TrackEventType.Gesture.longPress, properties: properties)
        }
    }
}
