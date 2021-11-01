//
//  ANSINodeSwitcher.swift
//
//  A set of nodes occupying the same space, with only one being visible at any time
//
//  The visible node is automatically forwarded events
//
//  Created by Eric Rabil on 10/31/21.
//

import Foundation

public protocol ANSINodeSwitcherDelegate {
    func switcher(_ nodeSwitcher: ANSINodeSwitcher, changedToIndex index: Int, node: ANSINode)
}

open class ANSINodeSwitcher: ANSINode, ANSINodeCustomCompositing {
    open var activeNodeIndex: Int = 0 {
        didSet {
            if children.count == 0 {
                return activeNodeIndex = 0
            }
            
            if !children.indices.contains(activeNodeIndex) {
                activeNodeIndex = children.count - 1
            }
            
            delegate?.switcher(self, changedToIndex: activeNodeIndex, node: children[activeNodeIndex])
        }
    }
    
    open var delegate: ANSINodeSwitcherDelegate?
    
    open var activeNode: ANSINode? {
        guard children.indices.contains(activeNodeIndex) else {
            return nil
        }
        
        return children[activeNodeIndex]
    }
    
    open override func render(withWidth width: Int) -> [String] {
        activeNode?.render(withWidth: width) ?? [.spaces(repeating: width)]
    }
    
    open override func activated() {
        activeNode?.activated()
    }
    
    open override func inputEventReceived(_ event: ANSIInputEvent) {
        activeNode?.inputEventReceived(event)
    }
    
    open override func deactivated() {
        activeNode?.deactivated()
    }
}
