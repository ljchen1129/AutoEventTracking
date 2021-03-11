//
//  Extended.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/10.
//

import Foundation

/// 增加命名空间，防止污染系统或者第三方库的方法
public struct AETExtension<ExtendedType> {
    let type: ExtendedType

    init(_ type: ExtendedType) {
        self.type = type
    }
}

public protocol AETExtended {
    associatedtype ExtendedType

    static var aet: AETExtension<ExtendedType>.Type { get set }
    var aet: AETExtension<ExtendedType> { get set }
}

public extension AETExtended {
    static var aet: AETExtension<Self>.Type {
        get { return AETExtension<Self>.self }
        set {}
    }

    var aet: AETExtension<Self> {
        get { return AETExtension(self) }
        set {}
    }
}

extension AutoEventTrackingManager: AETExtended {}
extension TrackEventType: AETExtended {}
extension Dictionary: AETExtended {}

extension AETExtension where ExtendedType == Dictionary<String, Any> {
    func jsonString(prettify: Bool = false) -> String? {
        guard JSONSerialization.isValidJSONObject(type) else { return nil }
        let options = (prettify == true) ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: type, options: options) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
}
