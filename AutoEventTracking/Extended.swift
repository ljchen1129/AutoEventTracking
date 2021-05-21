//
//  Extended.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/10.
//

import Foundation

/// 增加命名空间，防止污染系统或者第三方库的变量和方法
public struct Extension<ExtendedType> {
    let type: ExtendedType

    init(_ type: ExtendedType) {
        self.type = type
    }
}

public protocol Extended {
    associatedtype ExtendedType

    static var aet: Extension<ExtendedType>.Type { get set }
    var aet: Extension<ExtendedType> { get set }
}

public extension Extended {
    static var aet: Extension<Self>.Type {
        get { return Extension<Self>.self }
        set {}
    }

    var aet: Extension<Self> {
        get { return Extension(self) }
        set {}
    }
}

extension AutoEventTrackingManager: Extended {}
extension TrackEventType: Extended {}
extension Dictionary: Extended {}

extension Extension where ExtendedType == Dictionary<String, Any> {
    func jsonString(prettify: Bool = false) -> String? {
        guard JSONSerialization.isValidJSONObject(type) else { return nil }
        let options = (prettify == true) ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: type, options: options) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
}
