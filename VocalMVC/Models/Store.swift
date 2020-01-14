//
//  Store.swift
//  VocalMVC
//
//  Created by Omran Khoja on 1/12/20.
//  Copyright © 2020 AcronDesign. All rights reserved.
//

import Foundation

final class Store {
    
    //MARK: - Singleton Declaration
    
    static let shared = Store(url: documentDirectory)
    
    //MARK: - Properties
    private(set) var rootFolder: Folder
    
    static let changedNotification = Notification.Name("StoreChanged")
    
    //MARK: - Data Persistence Properties
    let baseURL: URL?
    var placeholder: URL?
    static private let documentDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    
    //MARK: Initialization

    /// Store is a singleton that will only be initialized statically with the initial url value of `documentDirectory` which will be the baseURL
    private init(url: URL?) {
        self.baseURL = url
        self.placeholder = nil
        
        /// Decode the `rootFolder` from the set path if it exists or create one
        if let url = url,
            let data = try? Data(contentsOf: url.appendingPathComponent(.dataSaveLocation)),
            let folder = try? JSONDecoder().decode(Folder.self, from: data)
        {
            rootFolder = folder
        } else {
            rootFolder = Folder(name: "", uuid: UUID())
        }
        
        /// Set `Self` as the `rootFolder's` store.
        rootFolder.store = self
    }
    
    
    //MARK: - Data Persistence Methods
    
    func save(_ item: Item, userInfo: [AnyHashable: Any]) {
        
        if let url = baseURL, let data = try? JSONEncoder().encode(rootFolder) {
            try! data.write(to: url.appendingPathComponent(.dataSaveLocation))
//             error handling ommitted
        }
        NotificationCenter.default.post(name: Store.changedNotification, object: item, userInfo: userInfo)
    }
    
    func item(atUUIDPath path: [UUID]) -> Item? {
        return rootFolder.item(atUUIDPath: path[0...])
    }
    
    func fileURL(for recording: Recording) -> URL? {
        return baseURL?.appendingPathComponent(recording.uuid.uuidString + ".m4a") ?? placeholder
    }
    
    func removeFile(for recording: Recording) {
        if let url = fileURL(for: recording), url != placeholder {
            _ = try? FileManager.default.removeItem(at: url)
        }
    }
    
    
}

fileprivate extension String {
    static let dataSaveLocation = "store.json"
}

