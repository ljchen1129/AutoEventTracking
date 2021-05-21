//
//  ExceptionHandler.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/5/21.
//

import Foundation

class ExceptionHandler {
    public static let shared = ExceptionHandler()
    
    static var previousExceptionHandler: ((NSException) -> Void)?
    private init() {
        // 获取之前保存的全局异常处理函数先保存下来
        ExceptionHandler.previousExceptionHandler = NSGetUncaughtExceptionHandler()
        
        // 全局异常处理
        NSSetUncaughtExceptionHandler { (exception) in
            AutoEventTrackingManager.shared.track(exception: TrackEventType.Exception.exception(exception))
            // 调用之前保存的 handler
            ExceptionHandler.previousExceptionHandler?(exception)
        }
        
        // unix signal
        enum Signal: Int32 {
            case HUP    = 1
            case INT    = 2
            case QUIT   = 3
            case ABRT   = 6
            case KILL   = 9
            case ALRM   = 14
            case TERM   = 15
        }
        
        func trap(signal: Signal, action: @escaping @convention(c) (Int32) -> ()) {
            // From Swift, sigaction.init() collides with the Darwin.sigaction() function.
            // This local typealias allows us to disambiguate them.
            typealias SignalAction = sigaction
            
            var signalAction = SignalAction(__sigaction_u: unsafeBitCast(action, to: __sigaction_u.self), sa_mask: 0, sa_flags: 0)
            let _ = withUnsafePointer(to: &signalAction) { actionPointer in
                sigaction(signal.rawValue, actionPointer, nil)
            }
        }
        
        trap(signal: .INT) { signal in
            print("intercepted signal \(signal)")
        }
    }
}
