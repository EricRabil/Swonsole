//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/16/21.
//

import Foundation

public protocol ANSIInputReceiver: ANSIView {
    var receivingInput: Bool { get set }
}

/// Concrete ANSIView
open class ERConcreteView: ANSIView, ANSIInputReceiver {
    open private(set) var mounted = false
    open var subviews: [ANSIView] {
        didSet {
            
        }
    }
    
    open var rows: [Paintable] { [] }
    open var receivingInput: Bool {
        get { source.active }
        set {
            source.active = newValue
            
            if newValue {
                didStartReceivingInput()
            } else {
                didStopReceivingInput()
            }
        }
    }
    
    public var renderWidth: Int = 0
    
    private lazy var source = ANSISourceConnection(inputReceived(_:))
    
    public init(subviews: [ANSIView] = []) {
        self.subviews = subviews
    }
    
    open func willMount() {
        mounted = true
    }
    
    open func unmounted() {
        mounted = false
    }
    
    open func willRender() {}
    open func willRender(withWidth width: Int) {
        renderWidth = width
        willRender()
    }
    
    open func rendered(toRows rows: [Int]) {}
    
    open func inputReceived(_ payload: ANSIPayload) {}
    
    open func didStartReceivingInput() {}
    open func didStopReceivingInput() {}
}

open class ERConcreteMutableView: ERConcreteView {
    private var _rows: [Paintable] = []
    
    open override var rows: [Paintable] {
        _read {
            yield _rows
        }
        _modify {
            yield &_rows
        }
    }
}
