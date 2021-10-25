//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

public class _MainThreadTrampoline: NSObject {
    var block: () -> ()
    
    init(_ block: @escaping () -> ()) {
        self.block = block
        super.init()
    }
    
    @objc private func run() {
        block()
    }
}

extension _MainThreadTrampoline {
    @_transparent
    func go() {
       if Thread.isMainThread {
           block()
       }
       
       performSelector(onMainThread: #selector(_MainThreadTrampoline.run), with: nil, waitUntilDone: false)
   }
}

public class ANSIRenderLink {
    public static func link(forView view: ANSIView) -> ANSIRenderLink? {
        ANSIViewRenderer.renderer(forView: view)?.link
    }
    
    public let renderer: ANSIViewRenderer
    
    private var source: DispatchSourceTimer? {
        didSet {
            oldValue?.cancel()
            source?.resume()
        }
    }
    
    fileprivate class ANSIViewLink {
        var pre = Set<ANSIReceiverRef<Int>>()
        var post = Set<ANSIReceiverRef<Int>>()
        
        func insertPre(_ callback: @escaping (Int) -> ()) -> () -> () {
            let receiver = ANSIReceiverRef(receiver: callback)
            pre.insert(receiver)
            return { self.pre.remove(receiver) }
        }
        
        func insertPost(_ callback: @escaping (Int) -> ()) -> () -> () {
            let receiver = ANSIReceiverRef(receiver: callback)
            post.insert(receiver)
            return { self.post.remove(receiver) }
        }
    }
    
    fileprivate var links: [ObjectIdentifier: ANSIViewLink] = [:]
    
    private var preLinks: [(Int) -> ()] {
        links.values.flatMap(\.pre).map(\.receiver)
    }
    
    private var postLinks: [(Int) -> ()] {
        links.values.flatMap(\.post).map(\.receiver)
    }
    
    fileprivate var frame = 1 {
        didSet {
            if frame > 60 {
                frame = 1
            }
        }
    }
    
    internal init(renderer: ANSIViewRenderer) {
        self.renderer = renderer
    }
    
    private func newSource() -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: .milliseconds(16))
        timer.setEventHandler(handler: wake)
        
        return timer
    }
    
    private func wake() {
        wakeOnThread()
    }
    
    @objc private func wakeOnThread() {
        preLinks.forEach { $0(frame) }
        renderer.render()
        postLinks.forEach { $0(frame) }
        frame += 1
    }
    
    internal func start() {
        source = newSource()
    }
    
    internal func stop() {
        source?.cancel()
        source = nil
    }
    
    internal func reset() {
        links = [:]
    }
}

private extension ANSIView {
    var link: ANSIRenderLink? {
        .link(forView: self)
    }
}

public extension ANSIView {
    private var viewLink: ANSIRenderLink.ANSIViewLink? {
        guard let link = link else {
            return nil
        }
        
        let viewLink = link.links[id] ?? .init()
        link.links[id] = viewLink
        return viewLink
    }
    
    @discardableResult
    func registerPreRenderLink(_ callback: @escaping (Int) -> ()) -> (() -> ())? {
        viewLink?.insertPre(callback)
    }
    
    @discardableResult
    func registerSinglePreRenderLink(_ callback: @escaping () -> ()) -> (() -> ())? {
        var remove: (() -> ())?
        
        guard let removeFn = viewLink?.insertPre ({ _ in
            remove?()
            callback()
        }) else {
            return nil
        }
        
        remove = removeFn
        
        return removeFn
    }
    
    @discardableResult
    func registerPostRenderLink(_ callback: @escaping (Int) -> ()) -> (() -> ())? {
        viewLink?.insertPost(callback)
    }
    
    @discardableResult
    func registerSinglePostRenderLink(_ callback: @escaping () -> ()) -> (() -> ())? {
        var remove: (() -> ())?
        
        guard let removeFn = viewLink?.insertPost ({ _ in
            remove?()
            callback()
        }) else {
            return nil
        }
        
        remove = removeFn
        
        return removeFn
    }
    
    func removeLinks() {
        link?.links[id] = nil
    }
}
