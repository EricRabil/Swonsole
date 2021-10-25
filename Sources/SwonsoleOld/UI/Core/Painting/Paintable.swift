//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/17/21.
//

import Foundation

/*
 Goal: concise syntax of passing paintable conformances up to the compositor
 
 View {
    var rows: Paintabile | [Paintable]
 }
 
 protocol Paintable { paint }
 
 extension String : Paintable { paint { self } }
 extension Array  : Paintable where Element : Paintable { paint { map { $0.paint } } }
 extension Array  : Paintable where Element = Paintable { paint { map { $0.paint } } }
 extension Array  : Paintable where Element = [Paintable} { paint { flatMap { $0.paint } } }
 
 let paintable = ""
 let paintable = ["a"]
 let paintable = ["a", View { }]
 let paintable = View { }
 let paintable = [ ... View ... " " ... [View] ... ]
 */

public protocol Paintable {
    /// You have this many columns, render your string
    func paint(toWidth width: Int) -> [String]
}

extension Array: ExpressibleByUnicodeScalarLiteral where Element == Paintable {
    @inlinable public init(unicodeScalarLiteral value: String) {
        self = [value]
    }
    
    public typealias UnicodeScalarLiteralType = String
}

extension String: Paintable {
    @inlinable public func paint(toWidth width: Int) -> [String] {
        [self]
    }
}

extension Array: ExpressibleByExtendedGraphemeClusterLiteral where Element == Paintable {}

extension Array: ExpressibleByStringLiteral where Element == Paintable {
    public typealias ExtendedGraphemeClusterLiteralType = String
    
    @inlinable public init(stringLiteral: String) {
        self.init(arrayLiteral: stringLiteral)
    }
}

extension Array {
    @inlinable public func paint(toWidth width: Int) -> [String] where Element : Paintable {
        flatMap { $0.paint(toWidth: width) }
    }
    
    @inlinable public func paint(toWidth width: Int) -> [String] where Element == Paintable {
        flatMap { $0.paint(toWidth: width) }
    }
    
    @inlinable public func paint(toWidth width: Int) -> [String] where Element == [Paintable] {
        flatMap { $0.paint(toWidth: width) }
    }
    
    public func paint(toWidth width: Int) -> [String] {
        fatalError()
    }
}
