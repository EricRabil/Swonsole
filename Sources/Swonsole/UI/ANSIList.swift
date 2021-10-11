//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/9/21.
//

import Foundation

public protocol ANSIListDelegate: ANSIPaginatorDelegate, ANSIViewDelegate {
    func numberOfRows(forList list: ANSIList) -> Int
    func text(forRow row: Int, inList list: ANSIList) -> String
    func list(_ list: ANSIList, selectedRow row: Int)
    func submit(_ list: ANSIList)
}

public extension ANSIListDelegate {
    func list(_ list: ANSIList, selectedRow row: Int) {}
    func submit(_ list: ANSIList) {}
}

public class ANSIStaticListDelegate: ANSIListDelegate {
    public var items: [String]
    
    public init(items: [String]) {
        self.items = items
    }
    
    public func numberOfRows(forList list: ANSIList) -> Int {
        items.count
    }
    
    public func text(forRow row: Int, inList list: ANSIList) -> String {
        items[row]
    }
}

public class ANSIList: ANSIView {
    public var delegate: ANSIListDelegate? {
        didSet {
            paginator.delegate = delegate
        }
    }
    
    public var activeIndex: Int = 0
    public var pageSize: Int = 5
    public var active: Bool { get { source.active } set { source.active = newValue } }
    public var allowsSelection = true
    
    public init(delegate: ANSIListDelegate? = nil) {
        self.delegate = delegate
        paginator.delegate = delegate
    }
    
    public convenience init(items: [String]) {
        self.init(delegate: ANSIStaticListDelegate(items: items))
    }
    
    private var paginator = ANSIPaginator()
    private lazy var source = ANSISourceConnection { payload in
        switch payload.code {
        case .up:
            self.scrollUp()
        case .down:
            self.scrollDown()
        default:
            switch payload.chars.first {
            case " ":
                guard self.allowsSelection else {
                    break
                }
                
                self.delegate?.list(self, selectedRow: self.activeIndex)
            case "\r":
                fallthrough
            case "\n":
                self.delegate?.submit(self)
            default:
                break
            }
        }
    }
    
    private var numberOfRows: Int {
        delegate?.numberOfRows(forList: self) ?? 0
    }
    
    private var rowIndices: [Int] {
        Array(0..<numberOfRows)
    }
    
    public var rows: [String] {
        let rowIndices = rowIndices
        var additional = [String]()
        
        if rowIndices.count - 1 < activeIndex {
            activeIndex = max(rowIndices.count - 1, 0)
        }
        
        if pageSize > rowIndices.count {
            for _ in 0..<pageSize - rowIndices.count {
                additional.append("")
            }
        }
        
        return paginator.paginate(indices: rowIndices, active: activeIndex, pageSize: pageSize).map { row in
            delegate?.text(forRow: row, inList: self) ?? ""
        } + additional
    }
}

public extension ANSIList {
    func scrollUp() {
        if activeIndex == 0 {
            activeIndex = max(numberOfRows - 1, 0)
        } else {
            activeIndex -= 1
        }
    }
    
    func scrollDown() {
        let end = numberOfRows - 1
        
        if activeIndex == end {
            activeIndex = 0
        } else {
            activeIndex += 1
        }
    }
}

public extension ANSIList {
    func willMount() {
        
    }
    
    func unmounted() {
        active = false
    }
}
