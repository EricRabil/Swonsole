//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/8/21.
//

import Foundation

private extension Array {
    var infinite: [Element] {
        self + self + self
    }
    
    func infiniteSlice(start: Index, maxLength: Int) -> [Element] {
        Array(Array(infinite[start...])[..<maxLength])
    }
}

struct Paginator {
    var pointer: Int = 0
    var lastIndex: Int = 0
    
    mutating func paginate(indices: [Int], active: Int, pageSize: Int) -> [Int] {
        let middle = pageSize / 2
        
        guard indices.count > pageSize else {
            return indices
        }
        
        if pointer < middle && lastIndex < active && (active - lastIndex) < pageSize {
            pointer = min(middle, pointer + active - lastIndex)
        }
        
        lastIndex = active
        
        let topIndex = max(0, active + indices.count - pointer)
        
        return indices.infiniteSlice(start: topIndex, maxLength: pageSize)
    }
}
