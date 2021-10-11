//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

public class ANSIViewCompositor {
    @usableFromInline
    internal var rowAssignments: [ObjectIdentifier: [Int]] = [:]
    
    public let views: [ANSIView]
    
    @usableFromInline
    internal var rows: [String] = []
    
    public init(views: [ANSIView]) {
        self.views = views
    }
    
    /// Calling this assumes you will inform the views that they rendered afterwards, vs. letting us manage it in the render function
    public func compile() {
        walk { leaf in
            if rowAssignments.keys.contains(leaf.id) {
                return
            }
            
            leaf.dispatchWillRender()
            rowAssignments[leaf.id] = insert(rows: leaf.rows)
            
            if leaf is ANSIViewCustomCompositing {
                walk(view: leaf) { child in
                    rowAssignments[child.id] = rowAssignments[leaf.id]
                }
            }
        }
    }
    
    public static func render(views: [ANSIView]) {
        ANSIViewCompositor(views: views).render()
    }
}

public extension ANSIViewCompositor {
    @inlinable func render() {
        compile()
        ANSIRenderer.shared.render(lines: rows)
        dispatch(offset: ANSIRenderer.shared.lastTop)
    }
}

// MARK: - Internal

internal extension ANSIViewCompositor {
    @inlinable func insert(rows insertRows: [String]) -> [Int] {
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
            }.map { $0 + offset }.sorted()
            
            view.rendered(toRows: assignments)
        }
    }
}

// MARK: - Helpers

internal extension ANSIViewCompositor {
    @inlinable func reduce<P>(value: P, view: ANSIView, cb: (ANSIView, inout P) -> ()) -> P {
        var value = value
        
        walk(view: view) { view in
            cb(view, &value)
        }
        
        return value
    }
    
    @inlinable func reduce<P>(view: ANSIView, cb: (ANSIView, inout [P]) -> ()) -> [P] {
        reduce(value: [], view: view, cb: cb)
    }
    
    @inlinable func walk(view: ANSIView, cb: (ANSIView) -> ()) {
        cb(view)
        
        for subview in view.subviews {
            walk(view: subview, cb: cb)
        }
    }
    
    @inlinable func walk(_ cb: (ANSIView) -> ()) {
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
