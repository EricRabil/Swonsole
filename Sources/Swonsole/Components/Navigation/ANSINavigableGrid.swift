//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/29/21.
//

import Foundation

public protocol ANSINavigableGridDelegate {
    func column(activated index: Int, replacing oldIndex: Int?)
}

open class ANSINavigableGrid: ANSIRowGroup {
    open var activeColumn = 0
    open var delegate: ANSINavigableGridDelegate?
    
    private var numberOfColumns: Int {
        children.count
    }
    
    private var lastColumn: Int {
        max(numberOfColumns - 1, 0)
    }
    
    open var enabled: Bool = false {
        didSet {
            if enabled {
                receiveDetachedInput()
            } else {
                stopReceivingDetachedInput()
            }
        }
    }
    
    open override func mounted() {
        enabled = true
    }
    
    open override func willUnmount() {
        enabled = false
    }
    
    open override func inputEventReceived(_ event: ANSIInputEvent) {
        dispatchingColumnChange {
            switch event.code {
            case .left:
                if activeColumn > 0 {
                    activeColumn -= 1
                }
            case .right:
                if activeColumn < lastColumn {
                    activeColumn += 1
                }
            default:
                return
            }
        }
    }
    
    open func delegating(to delegate: ANSINavigableGridDelegate?) -> Self {
        self.delegate = delegate
        return self
    }
    
    private func assertSafeActiveColumn() {
        if activeColumn > lastColumn {
            if numberOfColumns == 0 {
                activeColumn = 0
            } else {
                dispatchingNewColumnOnly {
                    activeColumn = lastColumn
                }
            }
        }
    }
    
    private func dispatchingColumnChange(_ callback: () -> ()) {
        let previousColumn = activeColumn
        callback()
        guard previousColumn != activeColumn else {
            return
        }
        delegate?.column(activated: activeColumn, replacing: previousColumn)
    }
    
    private func dispatchingNewColumnOnly(_ callback: () -> ()) {
        let previousColumn = activeColumn
        callback()
        guard previousColumn != activeColumn else {
            return
        }
        delegate?.column(activated: activeColumn, replacing: nil)
    }
}
