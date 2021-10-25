//
//  ANSIRowGroup.swift
//
//  Horizontal layout engine
//
//  Created by Eric Rabil on 10/23/21.
//

import Foundation

public enum ANSIHorizontalRule {
    case flex // take an even share of remaining space
    case fixed(width: Int) // take up this much space
    case ratio(Double) // take up a ratio of free space  ( 1/3, 1/2, etc )
    
    fileprivate var fixedSize: Int {
        switch self {
        case .fixed(width: let width):
            return width
        default:
            return 0
        }
    }
    
    fileprivate var ratio: Double {
        switch self {
        case .ratio(let ratio):
            return ratio
        default:
            return 0
        }
    }
}

// Normalize a set of ratios to summate to 1. Positions set to -1 (flex) will be given an even distribution.
private func normalize(ratios: [Int: Double]) -> [Int: Double] {
    var flexCount = 0, ratios = ratios
    
    for ratio in ratios.values {
        if ratio == -1 {
            flexCount += 1
        }
    }
    
    let ratioAllocation = 1.0 / Double(flexCount)
    var ratioSum = 0.0
    
    for (key, ratio) in ratios {
        if ratio == -1 {
            ratios[key] = ratioAllocation
        }
        
        ratioSum += ratios[key]!
    }
    
    return ratios.mapValues {
        $0 / ratioSum // divide ratio by sum of ratios to flatten to a 0.0-1.0 scale
    }
}

open class ANSIRowGroup: ANSINode, ANSINodeCustomCompositing {
    open var rules: [ANSIHorizontalRule] = []
    
    private func sizing(forWidth width: Int) -> [Int: Int] {
        var usableWidth = width
        
        var allocations: [Int: Int] = [:]
        var ratios: [Int: Double] = [:]
        
        for (index, rule) in rules.enumerated() {
            switch rule {
            case .fixed(width: let width): allocations[index] = width; usableWidth -= width
            case .ratio(let ratio): ratios[index] = ratio
            case .flex: ratios[index] = -1
            }
        }
        
        for (index, ratio) in normalize(ratios: ratios) {
            allocations[index] = Int(Double(usableWidth) * ratio)
        }
        
        return allocations
    }
    
    open override func render(withWidth width: Int) -> [String] {
        let sizings = sizing(forWidth: width)
        
        var rows: [String] = []
        
        for (index, node) in children.enumerated() {
            guard let sizing = sizings[index], sizing > 0 else {
                continue
            }
            
            let nodeRows = ANSIRenderNode(node, withWidth: sizing)
            
            for (index, row) in nodeRows.enumerated() {
                if index == rows.count {
                    rows.append("") // grow the rows array if theres no row for this already
                }
                
                rows[index] += row // append this section of the node to the row
            }
        }
        
        return rows
    }
}
