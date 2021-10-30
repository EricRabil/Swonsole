//
//  ANSIRowGroup.swift
//
//  Horizontal layout engine
//
//  Created by Eric Rabil on 10/23/21.
//

import Foundation

public protocol ANSINodeMinimumHeightConstraining: ANSINode {
    var minimumHeight: Int { get set }
}

public extension ANSINodeMinimumHeightConstraining {
    @inlinable func withMinimumHeight(_ height: Int) -> Self {
        minimumHeight = height
        return self
    }
}

open class ANSIRowGroup: ANSINode, ANSINodeCustomCompositing, ANSIHorizontallyRuled, ANSINodeMinimumHeightConstraining {
    open var rules: [ANSIHorizontalRule] = []
    open var minimumHeight: Int = 0
    open var separator: Character?
    
    open override func render(withWidth width: Int) -> [String] {
        var rows = rules.render(withWidth: width, separator: separator) { index, width in
            ANSIRenderNode(children[index], withWidth: width)
        }
        
        if minimumHeight > rows.count {
            rows = rows + Array(repeating: String.spaces(repeating: width), count: minimumHeight - rows.count)
        }
        
        return rows
    }
    
    open func withSeparator(_ separator: Character?) -> Self {
        self.separator = separator
        return self
    }
}
