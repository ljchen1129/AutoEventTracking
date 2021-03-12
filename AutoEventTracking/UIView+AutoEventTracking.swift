//
//  UIAp.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/9.
//

import UIKit

extension UIApplication {
    @objc public static func swiftLoad() {
        // 通过 @selector 获得被替换和替换方法的 SEL，作为 Hook:hookClass:fromeSelector:toSelector 的参数传入
        
        // hook sendAction(_:to:from:for:) 方法
        let fromSelectorSendAction = #selector(sendAction(_:to:from:for:))
        let toSelectorSendAction = #selector(hook_sendAction(_:to:from:for:))
        Hook.hook(classObject: Self.self, fromSelector: fromSelectorSendAction, toSelector: toSelectorSendAction)
    }
}

extension UIApplication {
    @objc func hook_sendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) -> Bool {
        // 插入执行代码
        if let wrapSender = sender as? TrackViewPropertyType  {
            insertToSendAction(action, to: target, from: wrapSender, for: event)
        }
        
        return hook_sendAction(action, to: target, from: sender, for: event)
    }
    
    func insertToSendAction(_ action: Selector, to target: Any?, from sender: TrackViewPropertyType, for event: UIEvent?) {
        // 是否应该埋点
        let shouldTrack = ((sender as? UISwitch) != nil) ||
                            ((sender as? UIStepper) != nil) ||
                            ((sender as? UISegmentedControl) != nil) ||
                            event?.allTouches?.randomElement()?.phase == .some(.ended)
        
        if shouldTrack {
            var properties: [String: Any] = [:]
            properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewType"] = NSStringFromClass(sender.viewType)
            
            if let trackViewText = sender.trackText {
                properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewText"] = trackViewText
            }
            if let trackViewController = sender.trackViewController {
                properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewController"] = NSStringFromClass(type(of: trackViewController))
            }
            if let trackViewControllerTitle = sender.trackViewController?.trackTitle {
                properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewControllerTitle"] = trackViewControllerTitle
            }
            
            AutoEventTrackingManager.shared.track(viewEvent: sender.event, properties: properties)
        }
    }
}

protocol TrackViewPropertyType where Self: UIView {
    var trackText: String? { get }
    var trackViewController: UIViewController? { get }
    var viewType: AnyClass { get }
    var event: TrackEventType.View { get }
}

extension TrackViewPropertyType {
    var trackText: String? {
        nil
    }
    
    var viewType: AnyClass {
        Self.self
    }
    
    var trackViewController: UIViewController? {
        var responder = self.next
        while responder != nil {
            if responder!.isKind(of: UIViewController.self) {
                return responder as? UIViewController
            } else {
                responder = responder?.next
            }
        }
        
        return nil
    }
    
    var event: TrackEventType.View {
        .click
    }
}

extension UIButton: TrackViewPropertyType {
    var trackText: String? {
        currentTitle
    }
    
    var event: TrackEventType.View {
        .click
    }
}

extension UILabel: TrackViewPropertyType {
    var trackText: String? {
        text
    }
    
    var event: TrackEventType.View {
        .click
    }
}

extension UISwitch: TrackViewPropertyType {
    var trackText: String? {
        "\(isOn)"
    }
    
    var event: TrackEventType.View {
        .switch
    }
}

extension UISlider: TrackViewPropertyType {
    var trackText: String? {
        "\(value)"
    }
    
    var event: TrackEventType.View {
        .slide
    }
}

extension UISegmentedControl: TrackViewPropertyType {
    var trackText: String? {
        titleForSegment(at: selectedSegmentIndex)
    }
}

extension UIStepper: TrackViewPropertyType {
    var trackText: String? {
        "\(value)"
    }
}

extension UIImageView: TrackViewPropertyType {}
