//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/16/21.
//

import Foundation

public protocol ANSIColumnViewDelegate: ANSISplitViewDelegate {
    func columnActivated(_ index: Int, oldColumn: Int)
    func columnDeactivated(_ index: Int)
}

public extension ANSIColumnViewDelegate {
    func columnActivated(_ index: Int, oldColumn: Int) {}
    func columnDeactivated(_ index: Int) {}
}

open class ANSIColumnView: ANSISplitView {
    open override var subviews: [ANSIView] {
        didSet {
            for view in subviews {
                (view as? ANSIColumnView)?.superview = self
            }
        }
    }
    
    @LoopedInt(\ANSIColumnView.subviews.count, initialValue: 0)
    open var activeColumn: Int {
        didSet {
            assert(activeColumn >= 0 && activeColumn < subviews.count)
            
            if let delegate = delegate as? ANSIColumnViewDelegate {
                delegate.columnDeactivated(oldValue)
                delegate.columnActivated(activeColumn, oldColumn: oldValue)
            }
            
            if forwardActivationEvents {
                if let activeView = activeView as? ANSIInputReceiver {
                    activeView.receivingInput = true
                }
                
                if subviews.indices.contains(oldValue), let oldView = subviews[oldValue] as? ANSIInputReceiver {
                    oldView.receivingInput = false
                }
            }
        }
    }
    
    open override func inputReceived(_ payload: ANSIPayload) {
        super.inputReceived(payload)
        
        let atBoundary: Bool = payload.code == .left ? atStart : payload.code == .right ? atEnd : false
        
        switch payload.code {
        case .left:
            activeColumn -= 1
            
            if atBoundary {
                alignRight()
            }
            
            assertInputReceivers()
        case .right:
            activeColumn += 1
            
            if atBoundary {
                alignLeft()
            }
            
            assertInputReceivers()
        default:
            break
        }
    }
    
    open var forwardActivationEvents = true // when true, subviews that respond to "receivingInput" will be automatically updated when the active column changes
    
    public var activeView: ANSIView {
        subviews[activeColumn]
    }
    
    // MARK: - Implementation
    fileprivate var superview: ANSIColumnView?
    fileprivate var activeColumnView: ANSIColumnView? {
        activeView as? ANSIColumnView
    }
    
    fileprivate var atStart: Bool {
        activeColumn == 0
    }
    
    fileprivate var atEnd: Bool {
        activeColumn == endIndex
    }
    
    fileprivate var endIndex: Int {
        subviews.count - 1
    }
    
    fileprivate var ignoringSuppression = false
    fileprivate var suppressingInput: Bool {
        activeColumnView != nil
    }
    
    fileprivate var lowestSelectedColumnView: ANSIColumnView {
        var view: ANSIColumnView = self
        
        while let nestedView = view.activeColumnView {
            view = nestedView
        }
        
        return view
    }
    
    fileprivate func withoutActivationForwarding(_ cb: () -> ()) {
        let original = forwardActivationEvents
        forwardActivationEvents = false
        cb()
        forwardActivationEvents = original
    }
    
    fileprivate func assertInputReceivers() {
        let lowestView = lowestSelectedColumnView
        
        for view in subviews {
            view._walk { view in
                if view === lowestView {
                    return false
                }
                
                (view as? ANSIInputReceiver)?.receivingInput = false
                
                return true
            }
        }
        
        lowestView.receivingInput = true
    }
    
    fileprivate func alignLeft() {
        walk {
            if let view = $0 as? ANSIColumnView {
                view.withoutActivationForwarding {
                    view.activeColumn = 0
                }
            }
        }
    }
    
    fileprivate func alignRight() {
        walk {
            if let view = $0 as? ANSIColumnView {
                view.withoutActivationForwarding {
                    view.activeColumn = view.endIndex
                }
            }
        }
    }
}

extension ANSIView {
    func _walk(_ cb: (ANSIView) -> Bool) {
        if !cb(self) {
            return
        }
        
        for view in subviews {
            view._walk(cb)
        }
    }
}
