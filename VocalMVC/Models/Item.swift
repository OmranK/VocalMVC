//
//  Item.swift
//  VocalMVC
//
//  Created by Omran Khoja on 1/12/20.
//  Copyright © 2020 AcronDesign. All rights reserved.
//

import Foundation

class Item {
    
    let uuid: UUID
    private(set) var name: String
    weak var store: Store?
    weak var parent: Folder? {
        didSet {
            store = parent?.store
        }
    }
    
    init(name: String, uuid: UUID) {
        self.name = name
        self.uuid = uuid
        self.store = nil
    }
    
    func setName(_ newName: String) {
        name = newName
        if let parent = parent {
            let (oldIndex, newIndex) = parent.reSort(changedItem: self)
            store?.save(self, userInfo: [Item.logDescription: Item.renamed,
                                         Item.oldValue: oldIndex,
                                         Item.newValue: newIndex,
                                         Item.parentFolder: parent])
        }
    }

    func deleted() {
        parent = nil
    }
    
    var uuidPath: [UUID] {
        var path = parent?.uuidPath ?? []
        path.append(uuid)
        return path
    }

    func item(atUUIDPath path: ArraySlice<UUID>) -> Item? {
        guard let first = path.first, first == uuid else { return nil }
        return self
    }


}

extension Item {
    static let logDescription = "logDescription"
    static let newValue = "newValue"
    static let oldValue = "oldValue"
    static let parentFolder = "parentFolder"
    static let renamed = "renamed"
    static let added = "added"
    static let removed = "removed"
}

