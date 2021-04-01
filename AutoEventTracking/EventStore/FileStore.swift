//
//  FileStore.swift
//  AutoEventTracking
//
//  Created by 陈良静 on 2021/3/31.
//

import Foundation

/// 事件存储策略
struct EventStorePolicy {
    static private let defaultMaxCountLimit: UInt = 1000
    static private let defaultMaxSizeLimit: UInt = 50 * 1024 * 1024
    static private let defaultMaxAgeLimit: TimeInterval = 30 * 60
    
    /// 最大存储条数限制
    var maxCountLimit: UInt
    /// 最大存储空间限制
    var maxSizeLimit: UInt
    /// 最大存储时长限制
    var maxAgeLimit: TimeInterval
    
    init(maxCountLimit: UInt = Self.defaultMaxCountLimit,
         maxSizeLimit: UInt = Self.defaultMaxSizeLimit,
         maxAgeLimit: TimeInterval = Self.defaultMaxAgeLimit) {
        
        self.maxCountLimit = maxCountLimit
        self.maxSizeLimit = maxSizeLimit
        self.maxAgeLimit = maxAgeLimit
    }
}

/// 文件存储
class FileStore {
    private let directoryName = NSStringFromClass(FileStore.self)
    private let eventDataFileName = "enventData.plist"
    
    private var events = [[String: Any]]()
    var allEvents: [[String: Any]] {
        self.queue.sync {
            events
        }
    }
    
    private var filePath: String?
    private var defaultFilePath: String? {
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last {
            let folder = cacheDir.appendingPathComponent(directoryName)
            let exist = FileManager.default.fileExists(atPath: folder.path)
            if !exist {
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,attributes: nil)
            }
            
            let path = folder.appendingPathComponent(eventDataFileName).path
            print("文件磁盘路径path = \(path)")
            
            return path
        }
        
        return nil
    }
    
    /// 串行队列
    private var queue: DispatchQueue
    private var policy: EventStorePolicy
    
    init(filePath: String? = nil, policy: EventStorePolicy = EventStorePolicy()) {
        self.filePath = filePath
        self.queue = DispatchQueue.init(label: "\(directoryName).serialQueue")
        self.policy = policy
        
        if self.filePath == nil {
            self.filePath = defaultFilePath
        }
        
        guard let path = self.filePath else {
            return
        }
        
        readAllEvents(from: path)
    }
    
    func save(event: [String: Any]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 如果超出最大缓存条数
            if self.events.count >= self.policy.maxCountLimit {
                self.events.removeFirst()
            }
            
            self.events.append(event)
            self.writeEventToFile()
        }
    }
    
    private func writeEventToFile() {
        do {
            let data = try JSONSerialization.data(withJSONObject: events, options: .prettyPrinted)
            if let path = filePath {
                try data.write(to: URL(fileURLWithPath: path))
            }
        } catch (let error) {
            print("data(withJSONObject obj: Any, options opt: JSONSerialization.WritingOptions = []) error : \(error)")
        }
    }
    
    func readAllEvents(from filePath: String) {
        queue.async { [weak self] in
            let data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
            if data == .some(nil) {

            } else {
                guard let allEvents = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String: Any]] else { return }
                self?.events = allEvents
            }
        }
    }
    
    /// 删除前 count 条 event 数据
    /// - Parameter count: 条数
    func removeEvents(for count: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }

            if count >= self.events.count || count < 0 {
                return
            }
            
            self.events.removeSubrange(0..<count)
        }
    }
}
