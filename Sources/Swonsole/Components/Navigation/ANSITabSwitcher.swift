//
//  ANSITabSwitcher.swift
//
//  Flips through a set of children based on the tab key
//
//  Created by Eric Rabil on 10/31/21.
//

import Foundation

internal extension ANSINode {
    private static var receiverTable: [ANSINode: () -> ()] = [:]
    
    func receiveDetachedInput() {
        stopReceivingDetachedInput()
        Self.receiverTable[self] = ANSIInputManager.shared.subscribe(callback: inputEventReceived(_:))
    }
    
    func stopReceivingDetachedInput() {
        Self.receiverTable.removeValue(forKey: self)?()
    }
}

open class ANSITabSwitcher: ANSINodeSwitcher {
    open var enabled: Bool = false {
        didSet {
            if enabled {
                receiveDetachedInput()
            } else {
                stopReceivingDetachedInput()
            }
        }
    }
    
    open override func inputEventReceived(_ event: ANSIInputEvent) {
        switch event.code {
        case .none:
            for char in event.characters {
                switch char {
                case "\t":
                    if event.modifiers.contains(.shift) {
                        if activeNodeIndex == 0 {
                            activeNodeIndex = children.count - 1
                        } else {
                            activeNodeIndex -= 1
                        }
                    } else {
                        if activeNodeIndex == children.count - 1 {
                            activeNodeIndex = 0
                        } else {
                            activeNodeIndex += 1
                        }
                    }
                    
                    break
                default:
                    break
                }
            }
        default:
            break
        }
    }
}
