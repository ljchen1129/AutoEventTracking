//
//  DataSync.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/31.
//

import Foundation

/// 事件同步
class EventSync {
    /// 服务器地址
    private var serverUrl: String
    
    private var session = URLSession()
    
    init(serverUrl: String) {
        self.serverUrl = serverUrl
        
        setupSession()
    }
    
    private func setupSession() {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 5
        config.timeoutIntervalForRequest = 30
        config.allowsCellularAccess = true
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        self.session = URLSession(configuration: config, delegate: nil, delegateQueue: queue)
    }
    
    /// 同步事件
    func flush(events: [String]) -> Bool {
        let jsonString = events.joined()
        print("flush eventsJsonString = \(jsonString)")
        
        guard let url = URL(string: serverUrl) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpBody = jsonString.data(using: .utf8)
        request.httpMethod = "POST"
        
        var flushSuccess = false
        let flushSemaohore = DispatchSemaphore(value: 0)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let _ = error {
                print("flush events request error = \(String(describing: error)) ")
                flushSemaohore.signal()
                return
            }
             
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                flushSemaohore.signal()
                return
            }
            
            if statusCode >= 200 && statusCode < 300 {
                // 成功
                flushSuccess = true
            } else {
                print("flush events request error = \(String(describing: response)) ")
            }
            
            flushSemaohore.signal()
        }
        
        task.resume()
        
        let _ = flushSemaohore.wait(timeout: DispatchTime.distantFuture)
        
        return flushSuccess
    }
}
