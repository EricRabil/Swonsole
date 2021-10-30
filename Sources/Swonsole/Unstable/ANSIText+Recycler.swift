//
//  ANSIText+Recycler.swift
//
//  Provides an API for recycling text nodes across render
//
//  Created by Eric Rabil on 10/29/21.
//

import Foundation

public extension ANSIText {
    private static var recycler: [ObjectIdentifier: [Int: ANSIText]] = [:]
    
    /// Release all text instances for an object
    static func release<Object: AnyObject>(forNode node: Object) {
        recycler.removeValue(forKey: ObjectIdentifier(node))
    }
    
    /// Returns an existing node for an index if present, or creates and stores
    @_optimize(speed) static func recycledNode<Object: AnyObject>(forNode node: Object, index: Int) -> ANSIText {
        let key = ObjectIdentifier(node)
        
        var text = recycler[key]?[index]
        
        if _fastPath(text != nil) {
            return text!
        }
        
        text = ANSIText()
        
        recycler[key, default: [:]][index] = text!
        
        return text!
    }
}
