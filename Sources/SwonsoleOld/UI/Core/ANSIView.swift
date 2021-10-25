//
//  File 2.swift
//  
//
//  Created by Eric Rabil on 10/9/21.
//

public protocol ANSIView: AnyObject {
    var rows: [Paintable] { get } // the rows this view occupies
    
//    var superview: ANSIView? { get set } // parent view, nil if top level
    var subviews: [ANSIView] { get /*set*/ } // views within this view
    
    func willMount()
    func mounted()
    func unmounted()
    
    func willRender(withWidth width: Int) // Any text beyond the width should be considered truncated. wrap accordingly. if you dont include this then willRender gets called
    func willRender()
    func rendered(toRows rows: ClosedRange<Int>)
}

/// Conformance to this protocol results in the compositor not rendering subviews. You are expected to include them in rows
public protocol ANSIViewCustomCompositing: ANSIView {}

public protocol ANSIViewDelegating: ANSIViewDelegatePuppeting_ {
    associatedtype Delegate
    var delegate: Delegate? { get set }
}

public protocol ANSIViewDelegate {
    func viewMounted(_ view: ANSIView)
    func viewWillMount(_ view: ANSIView)
    func viewUnmounted(_ view: ANSIView)
    func viewWillRender(_ view: ANSIView)
    func viewWillRender(_ view: ANSIView, withWidth: Int)
}

public extension ANSIViewDelegate {
    func viewMounted(_ view: ANSIView) {}
    func viewWillMount(_ view: ANSIView) {}
    func viewUnmounted(_ view: ANSIView) {}
    func viewWillRender(_ view: ANSIView) {}
    func viewWillRender(_ view: ANSIView, withWidth width: Int) { viewWillRender(view) }
}

public extension ANSIView {
    var rows: [Paintable] { [] }
    var subviews: [ANSIView] { [] }
    
    func mounted() {}
    func willMount() {}
    func unmounted() {}
    
    func willRender() {}
    func willRender(withWidth width: Int) { willRender() }
    func rendered(toRows rows: ClosedRange<Int>) {}
}

// MARK: - Internal

/// This protocol allows us to access the delegate without the PAT
public protocol ANSIViewDelegatePuppeting_: ANSIView {
    var _delegate: ANSIViewDelegate? { get }
}

public extension ANSIViewDelegating {
    var _delegate: ANSIViewDelegate? {
        delegate as? ANSIViewDelegate
    }
}
