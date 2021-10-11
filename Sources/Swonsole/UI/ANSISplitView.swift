//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

open class ANSIGroup: ANSIView {
    public var subviews: [ANSIView]
    
    public init(_ subviews: ANSIView...) {
        self.subviews = subviews
    }
    
    public var rows: [String] { [] }
    public func willRender() {}
    public func mounted() {}
}

private extension ANSIView {
    var dirtyRender: [String] {
        var rows: [String] = []
        
        func eat(view: ANSIView) {
            rows += view.rows
            view.subviews.forEach(eat(view:))
        }
        
        eat(view: self)
        
        return rows
    }
}

public class ANSISplitView: ANSIGroup, ANSIViewCustomCompositing {
    private lazy var cachedWidth: Int = ANSIScreen.readScreenSize().col
    
    public var width: Int {
        cachedWidth
    }
    
    public var subviewWidth: Int {
        width / subviews.count
    }
    
    public override var rows: [String] {
        let subviewWidth = subviewWidth
        
        let renderedSplits = subviews.map(\.dirtyRender).map { rows in
            (rows.map { row -> String in
                let offset = row.count - row.replacingOccurrences(of: #"(?:\x1B[@-_]|[\x80-\x9F])[0-?]*[ -/]*[@-~]"#, with: "", options: .regularExpression).count
                
                return String(row.padding(toLength: subviewWidth + offset, withPad: " ", startingAt: 0).prefix(subviewWidth + offset))
            }.enumerated(), rows.count)
        }
        
        let totalRows = renderedSplits.map(\.1).sorted(by: >)[0]
        
        return renderedSplits.map(\.0).reduce(into: Array(repeating: "", count: totalRows)) { rows, subrows in
            for (index, row) in subrows {
                rows[index] += row
            }
        }
    }
    
    public override func mounted() {
        registerPreRenderLink { frame in
            guard frame == 1 else {
                return
            }
            
            self.cachedWidth = ANSIScreen.readScreenSize().col
        }
    }
}
