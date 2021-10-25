//
//  Clashable.swift
//
//  Created by Eric Rabil on 10/23/21.
//

import Foundation

// Provides automatic conformance to hashable and equatable for classes, based on their ObjectIdentifier
public protocol Clashable: Hashable, AnyObject {}

extension Clashable {
    @_transparent @inlinable public var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
    
    @_transparent @inlinable public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs === rhs
    }
    
    @_transparent @inlinable public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}
