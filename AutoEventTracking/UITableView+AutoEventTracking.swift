//
//  UIScrollView+.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/11.
//

import UIKit

/// UITableViewCell didSelect 事件埋点
extension UITableView {
    @objc public static func swiftLoad() {
        // 通过 @selector 获得被替换和替换方法的 SEL，作为 Hook:hookClass:fromeSelector:toSelector 的参数传入
        
        // hook viewDidAppear 方法
        let fromSelectorAppear = #selector(setter: self.delegate)
        let toSelectorAppear = #selector(hook_set(delegate:))
        Hook.hook(classObject: Self.self, fromSelector: fromSelectorAppear, toSelector: toSelectorAppear)
    }
}

/// 代理对象消息转发
extension UITableView {
    @objc private func hook_set(delegate: UITableViewDelegate) {
        // 调用原来的方法
        hook_set(delegate: delegate)
        
        // 插入要执行的代码
        insertToSetDelegate()
    }
    
    private func insertToSetDelegate() {
        guard let tempDelgate = self.delegate else { return }
        
        let fromSelector = #selector(tempDelgate.tableView(_:didSelectRowAt:))
        // 判断原 delegate 对象是否实现 tableView(_:didSelectRowAt:)， 没有实现直接返回
        if !tempDelgate.responds(to: fromSelector) {
            return
        }

        let toSelector = #selector(hook_tableView(_:didSelectRowAt:))

        // 原 delegate 对象已经实现了 hook_tableView(_:didSelectRowAt:) 方法
        if tempDelgate.responds(to: toSelector) {
            return
        }
        
        // 获取原 delegate 实现的 tableView(_:didSelectRowAt:) 方法
        guard let fromMethod = class_getInstanceMethod(type(of: tempDelgate), fromSelector),
            let toMethod = class_getInstanceMethod(Self.self, toSelector) else { return }
        
        // 给原 delgate 添加 hook_tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) 方法
        if !class_addMethod(type(of: tempDelgate), toSelector, method_getImplementation(toMethod), method_getTypeEncoding(fromMethod)) {
            return
        }
        
        // 添加成功后，进行方法交换
        Hook.hook(classObject: type(of: tempDelgate), fromSelector: fromSelector, toSelector: toSelector)
    }
    
    @objc private func hook_tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        hook_tableView(tableView, didSelectRowAt: indexPath)
        
        // 上报事件
        var properties = [String: Any]()
        
        properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)view_position"] = "section:\(indexPath.section), row: \(indexPath.row)"
        
        let cell = tableView.cellForRow(at: indexPath)
        if let wrapCell = cell {
            properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewType"] = NSStringFromClass(wrapCell.viewType)
        }
        
        if let trackViewText = cell?.trackText {
            properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewText"] = trackViewText
        }
        if let trackViewController = cell?.trackViewController {
            properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewController"] = NSStringFromClass(type(of: trackViewController))
        }
        if let trackViewControllerTitle = cell?.trackViewController?.trackTitle {
            properties["\(AutoEventTrackingManager.shared.propertiesKeyFlag)ViewControllerTitle"] = trackViewControllerTitle
        }
        
        AutoEventTrackingManager.shared.track(view: TrackEventType.View.didSelect(view: nil, indexPath: nil), properties: properties)
    }
}

extension UITableViewCell: TrackViewPropertyType {
    var trackText: String? {
        content(fromView: self)
    }
}
