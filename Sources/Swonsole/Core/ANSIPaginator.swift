//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/9/21.
//

import Foundation

private extension Array {
    private var infinite: [Element] {
        self + self + self
    }
    
    func infiniteSlice(start: Int, maxLength: Int) -> [Element] {
        Array(Array(infinite[start...])[..<maxLength])
    }
}

public protocol ANSIPaginatorDelegate {
    func paginator(_ paginator: ANSIPaginator, pointerMoved pointer: Int)
}

public extension ANSIPaginatorDelegate {
    func paginator(_ paginator: ANSIPaginator, pointerMoved pointer: Int) {}
}

public class ANSIPaginator {
    public var pointer = 0 {
        didSet {
            delegate?.paginator(self, pointerMoved: pointer)
        }
    }
    
    public var lastIndex = 0
    public var pageSize = 5
    
    public var delegate: ANSIPaginatorDelegate?
    
    public func paginate(indices: [Int], active: Int, pageSize: Int) -> [Int] {
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
