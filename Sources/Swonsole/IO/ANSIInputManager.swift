//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/23/21.
//

import Foundation

/// Manages the dispatch of input to a single node within a tree, to prevent confusing behavior
public class ANSIInputManager: ANSITerminalDelegate {
    public static let shared = ANSIInputManager()
    
    private init() {
        ANSITerminal.shared.delegate = self
    }
    
    // Map of top-level node to active node, if any
    private var activeNodes: [ANSINode: ANSINode] = [:]
    
    // Input subscriptions that are not tied to the tree
    private var subscriptions: [UInt64: (ANSIInputEvent) -> ()] = [:]
    private var rng = SystemRandomNumberGenerator()
    
    // propogate an event to all active nodes that are mounted
    @usableFromInline internal func dispatch(event: ANSIInputEvent) {
        for node in activeNodes.values {
            guard node.isMounted else {
                node.deactivate() // this node is no longer active, remove it and skip it
                continue
            }
            
            node.inputEventReceived(event)
        }
        
        for subscription in subscriptions.values {
            subscription(event)
        }
    }
    
    @usableFromInline internal func node(isActive node: ANSINode) -> Bool {
        activeNodes.values.contains(node)
    }
    
    // removes the node if it is registered
    private func remove(node: ANSINode) {
        activeNodes = activeNodes.filter { $0.value !== node }
    }
    
    // MARK: - public api
    
    // stop sending input events to a given node
    @discardableResult public func deactivate(node: ANSINode) -> Bool {
        guard self.node(isActive: node) else {
            return false
        }
        
        remove(node: node)
        node.deactivated()
        
        return true
    }
    
    // start sending input events to a given node
    // the node must be in a mounted tree to receive inputs
    // this will replace any existing node in the tree that is receiving input
    @discardableResult public func activate(node: ANSINode) -> Bool {
        guard let topParent = node.topParent, topParent.isMounted else {
            return false // only nodes in a mounted tree may receive input
        }
        
        if activeNodes[topParent] === node {
            return true // already activated, no-op
        }
        
        if self.node(isActive: node) {
            remove(node: node) // we are moving this node to another topParent
        }
        
        activeNodes.removeValue(forKey: topParent)?.deactivated() // remove old receiver if any, and tell it it was deactivated
        activeNodes[topParent] = node // assign new node to parent
        node.activated() // tell the node it was activated
        
        return true
    }
    
    // indiscriminantly receive input events, returning a function used to unsubscribe
    @discardableResult public func subscribe(callback: @escaping (ANSIInputEvent) -> ()) -> () -> () {
        let key = rng.next()
        subscriptions[key] = callback
        
        return {
            self.subscriptions.removeValue(forKey: key)
        }
    }
}

internal extension ANSIInputManager {
    func terminal(_ terminal: ANSITerminal, receivedInput event: ANSIInputEvent) {
        dispatch(event: event)
    }
}

public extension ANSINode {
    @inlinable var isActive: Bool {
        ANSIInputManager.shared.node(isActive: self)
    }
    
    @inlinable @discardableResult func activate() -> Bool {
        ANSIInputManager.shared.activate(node: self)
    }
    
    @inlinable @discardableResult func deactivate() -> Bool {
        ANSIInputManager.shared.deactivate(node: self)
    }
}
