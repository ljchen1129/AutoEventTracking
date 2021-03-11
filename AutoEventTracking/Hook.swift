//
//  Hook.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/9.
//

import Foundation

class Hook: NSObject {
    static func hook(classObject: AnyClass, fromSelector: Selector, toSelector: Selector) {
        // 得到被替换类的实例方法, 替换类的实例方法
        guard let fromMethod = class_getInstanceMethod(classObject, fromSelector),
              let toMethod = class_getInstanceMethod(classObject, toSelector) else { return }
        
        // class_addMethod 返回成功表示被替换的方法没实现，然后会通过 class_addMethod 方法先实现；返回失败则表示被替换方法已存在，可以直接进行 IMP 指针交换
        if(class_addMethod(classObject, fromSelector, method_getImplementation(toMethod), method_getTypeEncoding(toMethod))) {
            // 进行方法的替换
            class_replaceMethod(classObject, toSelector, method_getImplementation(fromMethod), method_getTypeEncoding(fromMethod));
        } else {
            // 交换 IMP 指针
            method_exchangeImplementations(fromMethod, toMethod);
        }
    }
}

