//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/29/21.
//

import Foundation

public enum ANSIStringPositioning {
    case left, right, center
}

public extension ANSIStringPositioning {
    @_optimize(speed) func apply(text: String, width: Int) -> String {
        let count = text.count
        
        if count > width {
            return String(text.prefix(width))
        } else if count == width {
            return text
        } else {
            switch self {
            case .left: return text + String.spaces(repeating: Swift.max(width - count, 0))
            case .center:
                let gap = max(width - count, 0)
                let lw = Int(ceil(Double(gap) / 2)), rw = Int(floor(Double(gap) / 2))
                
                return String.spaces(repeating: lw) + text + String.spaces(repeating: rw)
            case .right: return String.spaces(repeating: Swift.max(width - count, 0)) + text
            }
        }
    }
}
