//
//  Recording.swift
//  VocalMVC
//
//  Created by Omran Khoja on 1/12/20.
//  Copyright © 2020 AcronDesign. All rights reserved.
//

import Foundation

class Recording: Item, Codable{
    
    var fileURL: URL? {
        return store?.fileURL(for: self)
    }
    
    override init(name: String, uuid: UUID) {
        super.init(name: name, uuid: uuid)
    }
    
    override func deleted() {
        store?.removeFile(for: self)
        super.deleted()
    }
    
    enum RecordingKeys: CodingKey { case name, uuid }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RecordingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let uuid = try container.decode(UUID.self, forKey: .uuid)
        super.init(name: name, uuid: uuid)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RecordingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(uuid, forKey: .uuid)
    }
}
