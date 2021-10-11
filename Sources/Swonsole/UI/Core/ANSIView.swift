//
//  File 2.swift
//  
//
//  Created by Eric Rabil on 10/9/21.
//

public protocol ANSIView: AnyObject {
    var rows: [String] { get }
    var subviews: [ANSIView] { get }
    var stale: Bool { get set }
    
    func willMount()
    func mounted()
    func unmounted()
    
    func willRender()
    func rendered(toRows rows: [Int])
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
}

public extension ANSIViewDelegate {
    func viewMounted(_ view: ANSIView) {}
    func viewWillMount(_ view: ANSIView) {}
    func viewUnmounted(_ view: ANSIView) {}
    func viewWillRender(_ view: ANSIView) {}
}

public extension ANSIView {
    var rows: [String] { [] }
    var subviews: [ANSIView] { [] }
    var stale: Bool { get { false } set { } }
    
    func mounted() {}
    func willMount() {}
    func unmounted() {}
    
    func willRender() {}
    func rendered(toRows rows: [Int]) {}
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
