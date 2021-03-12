//
//  UIViewController+AutoEventTracking.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/9.
//

import UIKit

extension UIViewController {
    @objc public static func swiftLoad() {
        // 通过 @selector 获得被替换和替换方法的 SEL，作为 Hook:hookClass:fromeSelector:toSelector 的参数传入
        
        // hook viewDidAppear 方法
        let fromSelectorAppear = #selector(viewDidAppear(_:))
        let toSelectorAppear = #selector(hook_viewDidAppear(_:))
        Hook.hook(classObject: Self.self, fromSelector: fromSelectorAppear, toSelector: toSelectorAppear)
        
        // hook viewWillDisappear 方法
        let fromSelectorDisappear = #selector(viewWillDisappear(_:))
        let toSelectorDisappear = #selector(hook_viewWillDisappear(_:))
        Hook.hook(classObject: Self.self, fromSelector: fromSelectorDisappear, toSelector: toSelectorDisappear)
    }
}

// MARK: - eventResponse

extension UIViewController {
    @objc private func hook_viewDidAppear(_ animated: Bool) {
        // 调用原方法
        hook_viewDidAppear(animated)
        
        // 插入执行代码
        if shouldTrack() {
            insertToViewDidAppear()
        }
    }
    
    @objc private func hook_viewWillDisappear(_ animated: Bool) {
        // 调用原方法
        hook_viewWillDisappear(animated)
        
        // 插入执行代码
        if shouldTrack() {
            insertToViewWillDisappear()
        }
    }
}

// MARK: - privateFunc

extension UIViewController {
    private func insertToViewDidAppear() {
        var properties: [String: Any] = [
            "\(AutoEventTrackingManager.shared.propertiesKeyFlag)page_Name": NSStringFromClass(Self.self)
        ]
        
        if let title = trackTitle {
            properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)page_Title"] = title
        }
        
        // 页面曝光
        AutoEventTrackingManager.shared.track(viewControllerEvent: TrackEventType.ViewController.expose, properties: properties)
    }
    
    private func insertToViewWillDisappear() {
        // TODO: 页面消失事件埋点上报
        
        
    }
    
    private func shouldTrack() -> Bool {
        let blackList = AutoEventTrackingManager.shared.viewControllerBlackList
        let blackListClass = blackList.compactMap{ NSClassFromString($0) }
        
        // 没有包含在黑名单里面，才埋点
        let result = blackListClass.filter{ self.isKind(of: $0) }.count == 0
        
        return result
    }
}

extension UIViewController {
    var trackTitle: String? {
        var title = content(fromView: navigationItem.titleView ?? UIView())
        if (title?.count ?? 0) == 0 {
            title = navigationItem.title
        }
        
        return title
    }
}

public func content(fromView view: UIView) -> String? {
    if view.isHidden || view.alpha == 0 {
        return nil
    }
    
    if view.isKind(of: UIButton.self) {
        return (view as? UIButton)?.titleLabel?.text
    } else if view.isKind(of: UILabel.self) {
        return (view as? UILabel)?.text
    } else if view.isKind(of: UITextView.self) {
        return (view as? UITextView)?.text
    } else if view.isKind(of: UITextField.self) {
        return (view as? UITextField)?.text
    } else {
        var titles = [String]()
        for subView in view.subviews {
            let title = content(fromView: subView)
            if let temp = title {
                titles.append(temp)
            }
        }
        
        return titles.filter{ $0.count != 0 }.joined(separator: "-")
    }
}
