//
//  ExceptionHandler.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/5/21.
//

import Foundation

class ExceptionHandler {
    public static let shared = ExceptionHandler()
    
    private init() {
        // 全局异常处理
        NSSetUncaughtExceptionHandler { (exception) in
            AutoEventTrackingManager.shared.track(exception: TrackEventType.Exception.exception(exception))
        }
    }
}
