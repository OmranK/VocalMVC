//
//  Folder.swift
//  VocalMVC
//
//  Created by Omran Khoja on 1/12/20.
//  Copyright © 2020 AcronDesign. All rights reserved.
//

import Foundation

class Folder: Item, Codable {
    
    private(set) var contents: [Item]
    
    override weak var store: Store? {
        didSet {
            contents.forEach { $0.store = store }
        }
    }
    
    override init(name: String, uuid: UUID) {
        contents = []
        super.init(name: name, uuid: uuid)
    }
    
    
    //MARK: - Folder creation/deletion
    
    func add(_ item: Item) {
        assert(contents.contains {$0 === item } == false)
        contents.append(item)
        item.parent = self
        let newIndex = contents.firstIndex { $0 === item }!
        store?.save(item, userInfo: [Item.logDescription: Item.added,
                                     Item.newValue: newIndex,
                                     Item.parentFolder: self])
    }
    
    func remove(_ item: Item) {
        guard let index = contents.firstIndex(where: { $0 === item }) else { return }
        item.deleted()
        contents.remove(at: index)
        store?.save(item, userInfo: [Item.logDescription: Item.removed,
                                     Item.oldValue : index,
                                     Item.parentFolder : self])
    }
    
    func reSort(changedItem: Item) -> (oldIndex: Int, newIndex: Int) {
        let oldIndex = contents.firstIndex { $0 === changedItem }!
        contents.sort(by: { $0.name < $1.name })
        let newIndex = contents.firstIndex { $0 === changedItem }!
        return (oldIndex, newIndex)
    }
    
    override func deleted() {
        for item in contents {
            remove(item)
        }
        super.deleted()
    }
    
    override func item(atUUIDPath path: ArraySlice<UUID>) -> Item? {
        guard path.count > 1 else { return super.item(atUUIDPath: path) }
        guard path.first == uuid else { return nil }
        let subsequent = path.dropFirst()
        guard  let second = subsequent.first else { return nil }
        return contents.first { $0.uuid == second }.flatMap { $0.item(atUUIDPath: subsequent) }
    }
    
    
    //MARK: - Codable Implementation Methods
    
    enum FolderKeys: CodingKey { case name, uuid, contents }
    enum ItemIdentifierKeys: CodingKey { case folder, recording }
    
    required init(from decoder: Decoder) throws {
        /// Initialize empty contents array to add items
        contents = [Item]()
        
        
        /// Decode and Initialize `Self` (Current Folder) by creating a container to decode by FolderKeys
        let container = try decoder.container(keyedBy: FolderKeys.self)
        let uuid = try container.decode(UUID.self, forKey: .uuid)
        let name = try container.decode(String.self, forKey: .name)
        super.init(name: name, uuid: uuid)
        
        /// Create a nestedUnkeyedContainer for mixed `Item` type array
        var nested = try container.nestedUnkeyedContainer(forKey: .contents)
        
        while true {
            /// Nest the nestedUnkeyedContainer array to create a wrapper container to check for and identify the `Item` subclass by using `ItemIdentifierKeys`
            let wrapper = try nested.nestedContainer(keyedBy: ItemIdentifierKeys.self)
            
            /// Decode the `Item` as the correct subclass (`Folders` or `Recordings`)  using the decodeIfPresent method with the wrapper container and `ItemIdentifierKeys`. Add the decoded object to the `contents` array.
            if let folder = try wrapper.decodeIfPresent(Folder.self, forKey: .folder) {
                contents.append(folder)
            } else if let recording = try wrapper.decodeIfPresent(Recording.self, forKey: .recording) {
                contents.append(recording)
            } else {
                break
            }
        }
        
        /// Set `Self` (Current Folder) as the parent of all `Folders` and `Recordings` in the `contents` array
        for item in contents {
            item.parent = self
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FolderKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(uuid, forKey: .uuid)
        var nested = container.nestedUnkeyedContainer(forKey: .contents)
        for item in contents {
            var wrapper = nested.nestedContainer(keyedBy: ItemIdentifierKeys.self)
            switch item {
            case let folder as Folder: try wrapper.encode(folder, forKey: .folder)
            case let recording as Recording: try wrapper.encode(recording, forKey: .recording)
            default: break
            }
        }
        _ = nested.nestedContainer(keyedBy: ItemIdentifierKeys.self)
    }
    
}

