//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/9/21.
//

import Foundation

final class Weak<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T?) {
        self.value = value
    }
}

public class ANSIViewRenderer: ANSIViewCompositorDelegate {
    private static var renderers = [Weak<ANSIViewRenderer>]()
    
    public private(set) var link: ANSIRenderLink!
    public private(set) var views: [ANSIView] = []
    private var started = false
    private lazy var compositor = ANSIViewCompositor(delegate: self)
    
    public init() {
        ANSIViewRenderer.renderers.append(Weak(self))
        link = ANSIRenderLink(renderer: self)
    }
    
    deinit {
        ANSIViewRenderer.renderers.removeAll(where: { $0.value === self })
    }
    
    public func start() {
        guard !started else {
            return
        }
        
        started = true
        
        ANSIRenderer.shared.resetPointer()
        ANSISource.shared.enable()
        
        link.start()
    }
    
    public func render() {
        compositor.render()
    }
    
    public func flush() {
        let views = views
        self.views = []
        ANSIRenderer.shared.shift()
        views.forEach { $0.dispatchUnmounted() }
    }
    
    public func stop() {
        guard started else {
            return
        }
        
        started = false
        
        link.stop()
        ANSISource.shared.disable()
        ANSISource.shared.removeReceivers()
    }
}

public extension ANSIViewRenderer {
    static func renderer(forView view: ANSIView) -> ANSIViewRenderer? {
        func walk(view otherView: ANSIView) -> Bool {
            if otherView === view {
                return true
            }
            
            for subview in otherView.subviews {
                if walk(view: subview) {
                    return true
                }
            }
            
            return false
        }
        
        for renderer in renderers {
            guard let renderer = renderer.value else {
                continue
            }
            
            for view in renderer.views {
                if walk(view: view) {
                    return renderer
                }
            }
        }
        
        return nil
    }
}

public extension ANSIViewRenderer {
    func mount(_ view: ANSIView) {
        view.dispatchWillMount()
        views.append(view)
        view.dispatchMounted()
    }
    
    func unmount(_ view: ANSIView) {
        views.removeAll {
            $0 === view
        }
        
        view.removeLinks()
        
        view.unmounted()
        
        if let view = view as? ANSIViewDelegatePuppeting_ {
            view._delegate?.viewUnmounted(view)
        }
    }
}

extension ANSIView {
    @inlinable internal var __delegate: ANSIViewDelegate? {
        (self as? ANSIViewDelegatePuppeting_)?._delegate
    }
    
    @inlinable internal func dispatchWillRender(withWidth width: Int) {
        willRender(withWidth: width)
        __delegate?.viewWillRender(self, withWidth: width)
        
        if !(self is ANSIViewCustomCompositing) {
            subviews.forEach { $0.willRender(withWidth: width) }
        }
    }
    
    @inlinable internal func dispatchMounted() {
        mounted()
        __delegate?.viewMounted(self)
        
        subviews.forEach {
            $0.dispatchMounted()
        }
    }
    
    @inlinable internal func dispatchWillMount() {
        willMount()
        __delegate?.viewWillMount(self)
        
        subviews.forEach {
            $0.dispatchWillMount()
        }
    }
    
    @inlinable internal func dispatchUnmounted() {
        unmounted()
        __delegate?.viewUnmounted(self)
        
        subviews.forEach {
            $0.dispatchUnmounted()
        }
    }
}
