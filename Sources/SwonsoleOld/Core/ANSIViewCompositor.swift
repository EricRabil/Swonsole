//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

public protocol ANSIViewCompositorDelegate {
    var views: [ANSIView] { get }
}

public struct ANSIViewCompositor {
    @usableFromInline internal var rowAssignments: [ObjectIdentifier: [Int]] = [:]
    @usableFromInline internal var views: [ANSIView] { delegate.views }
    @usableFromInline internal var rows: [String] = []
    
    public var delegate: ANSIViewCompositorDelegate
    
    public init(delegate: ANSIViewCompositorDelegate) {
        self.delegate = delegate
        _ANSIScreenInterface.registerIfNeeded()
    }
    
    /// Calling this assumes you will inform the views that they rendered afterwards, vs. letting us manage it in the render function
    /// Flushes screen size measurements and compositing caches
    @usableFromInline internal mutating func compile() {
        flush()
        
        walk { leaf in
            if rowAssignments.keys.contains(leaf.id) {
                return false
            }
            
            leaf.dispatchWillRender(withWidth: ANSIScreen.screenColumns)
            rowAssignments[leaf.id] = insert(rows: leaf.rows.flatMap { row in
                row.paint(toWidth: ANSIScreen.screenColumns)
            })
            
            return !(leaf is ANSIViewCustomCompositing)
        }
    }
    
    @usableFromInline mutating func flush() {
        rowAssignments = [:]
        rows = []
    }
    
    @inlinable mutating func render() {
        compile()
        ANSIRenderer.shared.render(lines: rows)
        dispatch(offset: ANSIRenderer.shared.pointer)
    }
}

// MARK: - Internal

internal extension Collection where Element == Int {
    @usableFromInline func range(offsetBy offset: Int = 0) -> ClosedRange<Int> {
        guard let min = self.min(), let max = self.max() else {
            return (offset...offset)
        }
        
        return (min + offset)...(max + offset)
    }
}

internal extension ANSIViewCompositor {
    @inlinable mutating func insert(rows insertRows: [String]) -> [Int] {
        guard insertRows.count > 0 else {
            return []
        }
        
        let start = rows.endIndex
        rows.append(contentsOf: insertRows)
        let end = rows.index(before: rows.endIndex)
        
        return Array(start...end)
    }
    
    @inlinable func dispatch(offset: Int) {
        walk { view in
            let assignments = reduce(view: view) { view, assignments in
                assignments += rowAssignments[view.id] ?? []
                
                return true
            }.map { $0 + offset }.sorted()
            
            view.rendered(toRows: assignments.range(offsetBy: offset))
            
            return !(view is ANSIViewCustomCompositing)
        }
    }
}

// MARK: - Helpers

internal extension ANSIViewCompositor {
    @inlinable func reduce<P>(value: P, view: ANSIView, cb: (ANSIView, inout P) -> Bool) -> P {
        var value = value
        
        walk(view: view) { view in
            cb(view, &value)
        }
        
        return value
    }
    
    @inlinable func reduce<P>(view: ANSIView, cb: (ANSIView, inout [P]) -> Bool) -> [P] {
        reduce(value: [], view: view, cb: cb)
    }
    
    @inlinable func walk(view: ANSIView, cb: (ANSIView) -> Bool) {
        guard cb(view) else {
            return
        }
        
        for subview in view.subviews {
            walk(view: subview, cb: cb)
        }
    }
    
    @inlinable func walk(_ cb: (ANSIView) -> Bool) {
        for view in views {
            walk(view: view, cb: cb)
        }
    }
}

internal extension ANSIView {
    @inlinable
    var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}
