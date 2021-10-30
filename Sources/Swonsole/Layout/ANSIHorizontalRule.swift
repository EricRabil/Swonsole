//
//  ANSIHorizontalRule.swift
//
//  Provides the math needed to distribute size along a horizontal plane
//
//  Created by Eric Rabil on 10/28/21.
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

public extension Array where Element == ANSIHorizontalRule {
    // Normalize a set of ratios to summate to 1. Positions set to -1 (flex) will be given an even distribution.
    private func normalize(ratios: inout [Int: Double]) {
        let flexCount = ratios.values.filter { $0 == -1 }.count
        
        let ratioAllocation = 1.0 / Double(flexCount)
        var ratioSum = 0.0
        
        ratios = ratios.mapValues { ratio in
            var ratio = ratio
            
            if ratio == -1 {
                ratio = ratioAllocation
            }
            
            ratioSum += ratio
            
            return ratio
        }
        
        ratios = ratios.mapValues { ratio in
            ratio / ratioSum // divide ratio by sum of ratios to flatten to a 0.0-1.0 scale
        }
    }
    
    private func sizing(forWidth width: Int) -> [Int: Int] {
        var usableWidth = width
        let count = count
        
        var allocations = [Int: Int](minimumCapacity: count)
        var ratios = [Int: Double](minimumCapacity: count)
        
        for (index, rule) in enumerated() {
            switch rule {
            case .fixed(width: let width): allocations[index] = width; usableWidth -= width
            case .ratio(let ratio): ratios[index] = ratio
            case .flex: ratios[index] = -1
            }
        }
        
        normalize(ratios: &ratios)
        
        for (index, ratio) in ratios {
            allocations[index] = Int(Double(usableWidth) * ratio)
        }
        
        return allocations
    }
    
    func render(withWidth width: Int, separator: Character?, callback: (_ index: Int, _ width: Int) -> [String]) -> [String] {
        let count = count
        let width = separator == nil ? width : width - (Swift.max(0, count - 1))
        
        let sizings = sizing(forWidth: width)
        
        var rows: [String] = []
        
        for columnIndex in indices {
            guard let sizing = sizings[columnIndex], sizing >= 0 else {
                continue
            }
            
            let nodeRows = callback(columnIndex, sizing)
            
            for (index, row) in nodeRows.enumerated() {
                if index == rows.count {
                    rows.append("") // grow the rows array if theres no row for this already
                }
                
                rows[index] += row // append this section of the node to the row
                
                if let separator = separator, columnIndex != count - 1 {
                    rows[index].append(separator)
                }
                
                if sizing > row.count {
                    rows[index] += String.spaces(repeating: sizing - row.count)
                }
            }
        }
        
        return rows
    }
    
    @inlinable func render(withWidth width: Int, callback: (_ index: Int, _ width: Int) -> [String]) -> [String] {
        render(withWidth: width, separator: nil, callback: callback)
    }
}

// A node whose sublayouts are determined by a set of horizontal rules
public protocol ANSIHorizontallyRuled: ANSINodeCustomCompositing {
    var rules: [ANSIHorizontalRule] { get set }
}

public extension ANSIHorizontallyRuled {
    func withRules(_ rules: ANSIHorizontalRule...) -> Self {
        self.rules = rules
        return self
    }
}
