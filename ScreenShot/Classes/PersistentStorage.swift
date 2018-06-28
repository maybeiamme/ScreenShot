//
//  PersistentStorage.swift
//  ScreenShotApp
//
//  Created by Jin Hyong Park on 18/4/17.
//  Copyright © 2017 Jin. All rights reserved.
//
import CoreData

typealias PersistentStorageDataCompletionHandler = (Array<Data>) -> ()
typealias PersistentStorageFailureHandler = (Error) -> ()

internal enum PersistentStorageError: Error {
    case emptyRecordError
    case persistentStorageInstanceNotExistError
}

internal protocol PersistentStorage {
    func insert(data: Data, sessionId: String)
    func datas(for sessionId: String, completion: @escaping PersistentStorageDataCompletionHandler, failure: @escaping PersistentStorageFailureHandler) throws
}

internal final class MemoryPersistentStorage: PersistentStorage {
    private var storage = Array<Data>()
    internal func insert(data: Data, sessionId: String) {
        if storage.count >= 1024 {
            storage.remove(at: 0)
        }
        storage.append(data)
    }
    
    internal func datas(for sessionId: String, completion: @escaping PersistentStorageDataCompletionHandler, failure: @escaping PersistentStorageFailureHandler) throws {
        completion(storage)
    }
}

@available(iOS 9.0, *)
internal final class CoreDataPersistentStorage: PersistentStorage {
    private let moc: NSManagedObjectContext
    private let maxFramePerSession: Int
    private var sessionFrameCountCache: Dictionary<String, Int> = Dictionary<String, Int>()
    private let workQueue = DispatchQueue(label: "com.jin.coredata", attributes: DispatchQueue.Attributes.concurrent)
    
    internal func insert(data: Data, sessionId: String) {
        moc.perform { [weak self] in
            do {
                try self?.insertionInGlobalQueue(data: data, sessionId: sessionId)
            } catch {
                print("insertion failure with error : [\(error)]")
            }
        }
    }
    
    internal func datas(for sessionId: String, completion: @escaping PersistentStorageDataCompletionHandler, failure: @escaping PersistentStorageFailureHandler) {
        let request = NSFetchRequest<Time>(entityName: "Time")
        request.predicate = NSPredicate(format: "sessionId == %@", sessionId)
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async { [weak self] in
            do {
                guard let results = try self?.moc.fetch(request) else {
                    failure(PersistentStorageError.persistentStorageInstanceNotExistError)
                    return
                }
                let datas = results.compactMap{ $0.image?.image }
                completion(datas)
            } catch {
                failure(error)
            }
        }
    }
    
    private func insertionInGlobalQueue(data: Data, sessionId: String) throws {
        if sessionFrameCountCache[sessionId] == nil {
            sessionFrameCountCache[sessionId] = try frameCount(for: sessionId)
        }
        if let sessionFrameCount = sessionFrameCountCache[sessionId],
            sessionFrameCount >= maxFramePerSession {
            removeFirstRecord(for: sessionId)
            sessionFrameCountCache[sessionId] = sessionFrameCount - 1
        }
        
        let time = NSEntityDescription.insertNewObject(forEntityName: "Time", into: moc) as? Time
        time?.timestamp = Date()
        time?.sessionId = sessionId
        
        let image = NSEntityDescription.insertNewObject(forEntityName: "Images", into: moc) as? Images
        image?.image = data
        
        time?.image = image

        sessionFrameCountCache[sessionId] = (sessionFrameCountCache[sessionId] ?? 0) + 1
    }
    
    private func removeFirstRecord(for sessionId: String) {
        let request = NSFetchRequest<Time>(entityName: "Time")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        do {
            let results = try moc.fetch(request)
            guard let first = results.first else {
                throw PersistentStorageError.emptyRecordError
            }
            moc.delete(first)
        } catch {
            print("remove last frame error : [\(error)]")
        }
    }
    
    private func frameCount(for sessionId: String) throws -> Int {
        let fetchRequest = NSFetchRequest<Time>(entityName: "Time")
        fetchRequest.predicate = NSPredicate(format: "sessionId == %@", sessionId )
        let results = try moc.fetch(fetchRequest)
        return results.count
    }
    
    internal init(maxFramePerSession: Int = 1024) {
        let name = "Model"
        let modelUrl = Bundle(for: type(of: self)).url(forResource: name, withExtension: "momd")
        let mom = NSManagedObjectModel(contentsOf: modelUrl!)
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docUrl = urls[urls.endIndex-1]
        let storeURL = docUrl.appendingPathComponent(name + ".sqlite")
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            fatalError("Failed to create core data")
        }
        self.maxFramePerSession = maxFramePerSession
        self.moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = psc
    }
}
