//
//  Notifier.swift
//  VocalMVC
//
//  Created by Omran Khoja on 1/13/20.
//  Copyright © 2020 AcronDesign. All rights reserved.
//

import Foundation


protocol Notifier {
    associatedtype Notification: RawRepresentable
}

//extension Notifier where Notification.RawValue == String {
    
extension Notifier {
    
    private static func nameFor(notification: Notification) -> NSNotification.Name {
        return NSNotification.Name(rawValue: "\(self).\(notification.rawValue)")
    }

    static func addObserver(_ observer: AnyObject, selector: Selector, notification: Notification) {
        let name = nameFor(notification: notification)
        
        NotificationCenter.default.addObserver(observer, selector: selector, name: name, object: nil)
    }
    
    
    // Post Notification
    func postNotification(notification: Notification, object: AnyObject? = nil) {
        Self.postNotification(notification: notification, object: object)
    }
    
    func postNotification(notification: Notification, object: AnyObject?, userInfo: [AnyHashable : Any]?) {
        Self.postNotification(notification: notification, object: object, userInfo: userInfo)
    }
    
    static func postNotification(notification: Notification, object: AnyObject? = nil, userInfo: [AnyHashable : Any]? = nil) {
        let name = nameFor(notification: notification)
    
        NotificationCenter.default
            .post(name: name, object: object, userInfo: userInfo)
    
    }
    
    // Remove Observer
    static func removeObserver(observer: AnyObject, notification: Notification, object: AnyObject? = nil) {
        let name = nameFor(notification: notification)
            NotificationCenter.default
                .removeObserver(observer, name: name, object: object)
    }
}
