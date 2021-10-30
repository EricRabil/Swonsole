//
//  ANSINode.swift
//  
//
//  Created by Eric Rabil on 10/23/21.
//

import Foundation

open class ANSINode: Clashable {
    public fileprivate(set) var parent: ANSINode?
    public fileprivate(set) var children: [ANSINode] = [] // children of this node
    public fileprivate(set) var isMounted: Bool = false
    
    open var hidden = false
    
    public init() {}
    public init(children: [ANSINode]) {
        for child in children {
            append(node: child)
        }
    }
    
    public convenience init(_ children: ANSINode...) {
        self.init(children: children)
    }
    
    open func render(withWidth width: Int) -> [String] {
        []
    } // rows to be rendered, the space this node takes
    
    open func mounted() {
        
    } // we are now in the tree
    
    open func willUnmount() {
        
    } // teardown, we are about to leave the tree
    
    open func activated() {
        
    } // we are now receiving input
    
    open func inputEventReceived(_ event: ANSIInputEvent) {
        
    } // input received! yay
    
    open func deactivated() {
        
    } // we are no longer receiving input
}

// Classes that conform to this will vend their own representation of their children
// Their children will not be tacked in front of the rows they provide
// They can take up as many rows as they want, and are expended to render children
// according to the width provided in the render function
public protocol ANSINodeCustomCompositing: ANSINode {}

// MARK: - Internals

fileprivate extension ANSINode {
    func propagate(mounted: Bool) {
        if mounted == isMounted {
            return
        }
        
        isMounted = mounted
        walkChildren {
            $0.isMounted = mounted
        }
    }
}

/// For renderer use only
internal extension ANSINode {
    func enteredRenderer() {
        propagate(mounted: true)
    }
    
    func leftRenderer() {
        propagate(mounted: false)
    }
}

// Lifecycle propagation
internal extension ANSINode {
    @inlinable func emitWillUnmount() {
        willUnmount()
        
        walkChildren {
            $0.willUnmount()
        }
    }
    
    @inlinable func emitMounted() {
        mounted()
        
        walkChildren {
            $0.mounted()
        }
    }
}

// MARK: - Common APIs

// Manipulation
public extension ANSINode {
    // remove from parent, returning true if the child was allowed to be removed
    @discardableResult func remove(silently: Bool = false) -> Bool {
        guard let parent = parent, parent.children.contains(self) else {
            return false
        }
        
        if !silently, isMounted {
            emitWillUnmount()
        }
        
        parent.children.removeAll(where: { $0 === self })
        propagate(mounted: false)
        
        return true
    }
    
    // remove child
    @discardableResult func remove(node: ANSINode) -> Bool {
        guard node.parent === self else {
            return false
        }
        
        return node.remove()
    }
    
    // add child, returning true if the child was allowed to be added
    @discardableResult func append(node: ANSINode) -> Bool {
        guard !children.contains(where: { $0 === node }) else {
            return false
        }
        
        let wasMounted = node.isMounted
        
        if node.isMounted && !isMounted {
            node.emitWillUnmount()
        }
        
        node.parent?.children.removeAll(where: { $0 === node }) // remove node from old parent
        
        children.append(node) // add node to our list
        node.parent = self
        node.propagate(mounted: isMounted)
        
        if isMounted && !wasMounted {
            node.emitMounted()
        }
        
        return true
    }
}

// Iteration
public extension ANSINode {
    // All parents, ordered by closest to furthest
    var allParents: [ANSINode] {
        guard var parent = parent else {
            return []
        }
        
        var parents = [ANSINode]()
        
        while true {
            parents.append(parent)
            if parent.parent == nil {
                break
            }
            parent = parent.parent!
        }
        
        return parents
    }
    
    // The very top of the tree of this node
    var topParent: ANSINode? {
        guard var parent = parent else {
            return nil
        }
        
        while let nextParent = parent.parent {
            parent = nextParent
        }
        
        return parent
    }
    
    // Invokes a callback of all children within this node, iterating in the sequence of all nested nodes from left to right
    @_optimize(speed) @inlinable func walkChildren(_ callback: (ANSINode) throws -> Bool) rethrows {
        for node in children {
            guard try callback(node) else {
                break
            }
            
            try node.walkChildren(callback)
        }
    }
    
    // Base iteration function
    @_optimize(speed) @inlinable func walkChildren(_ callback: (ANSINode) throws -> ()) rethrows {
        for node in children {
            try callback(node)
            try node.walkChildren(callback)
        }
    }
    
    @_optimize(speed) @inlinable func reduceChildren<Value>(into value: inout Value, callback: (inout Value, ANSINode) throws -> ()) rethrows {
        try walkChildren { node in
            try callback(&value, node)
        }
    }
    
    @_optimize(speed) @inlinable func reduceChildren<Value>(into value: Value, callback: (inout Value, ANSINode) throws -> ()) rethrows -> Value {
        var value = value
        
        try walkChildren { node in
            try callback(&value, node)
        }
        
        return value
    }
    
    @_optimize(speed) @inlinable func reduceChildren<Value>(initial value: Value, callback: (Value, ANSINode) throws -> Value) rethrows -> Value {
        var value = value
        
        try walkChildren { node in
            value = try callback(value, node)
        }
        
        return value
    }
    
    @_optimize(speed) @inlinable func mapChildren<Value>(callback: (ANSINode) throws -> Value) rethrows -> [Value] {
        try reduceChildren(into: [Value]()) { children, node in
            try children.append(callback(node))
        }
    }
    
    // All children, from left to right, within this node
    @inlinable var flatChildren: [ANSINode] {
        mapChildren { $0 }
    }
    
    // Number of total nodes within this node
    @inlinable var flatCount: Int {
        reduceChildren(initial: 0) { number, _ in number + 1 }
    }
}
