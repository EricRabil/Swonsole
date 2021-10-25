//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/22/21.
//

import Foundation

public protocol ANSIListDelegate_: ANSIViewDelegate {
    func numberOfRows(inList list: ANSIList_) -> Int
    func paint(row: Int, toWidth width: Int) -> Paintable
    func list(_ list: ANSIList_, selectedRow row: Int)
}

public extension ANSIListDelegate_ {
    func list(_ list: ANSIList_, selectedRow row: Int) {
        
    }
}

open class ANSIList_: ERConcreteMutableView, ANSIViewCustomCompositing {
    open var delegate: ANSIListDelegate_?
    
    @LoopedInt(\ANSIList_.numberOfRows, initialValue: 0) open var activeRow: Int {
        didSet {
            delegate?.list(self, selectedRow: activeRow)
        }
    }
    
    open var pageSize: Int = 10
    
    public let paginator = ANSIPaginator()
    
    private var numberOfRows: Int = 0 {
        didSet {
            if activeRow > numberOfRows {
                activeRow = max(numberOfRows - 1, 0)
            }
        }
    }
    
    open override func inputReceived(_ payload: ANSIPayload) {
        switch payload.code {
        case .up:
            activeRow -= 1
        case .down:
            activeRow += 1
        default:
            return
        }
    }
    
    private var rowText: [Int: Paintable] = [:]
    private var indices: [Int] = []
    
    private func refresh(withWidth width: Int) {
        numberOfRows = delegate?.numberOfRows(inList: self) ?? 0
        indices = paginator.paginate(indices: Array(0..<numberOfRows), active: activeRow, pageSize: pageSize)
        rowText = Set(indices).reduce(into: [Int: String]()) { dict, index in
            dict[index] = delegate?.paint(row: index, toWidth: width)
        }
    }
    
    open override func rendered(toRows rows: [Int]) {
    }
    
    open override func willRender(withWidth width: Int) {
        refresh(withWidth: width)
        
        if indices.count >= rows.count {
            rows.removeAll(keepingCapacity: true)
        } else {
            rows.removeAll()
        }
        
        for index in indices {
            rows.append(rowText[index] ?? "")
        }
    }
}
