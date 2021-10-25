//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/16/21.
//

import Foundation

internal protocol _ANSIColumnCompositorDelegate {
    func width(forColumn columnIndex: Int) -> Int
    func numberOfColumns() -> Int
}

internal class _ANSIColumnCompositor {
    var oldColumns: [[String]] = [], oldWidth: Int = 0, oldRender: [String] = []
    var columns: [[String]] = []
    var delegate: _ANSIColumnCompositorDelegate
    
    init(delegate: _ANSIColumnCompositorDelegate) {
        self.delegate = delegate
    }
    
    var rows: [ObjectIdentifier: (first: Int, last: Int)] = [:]
    
    var verticalBorder: String?
    var outsideBorder = false
    
    func flush(newSize: Int) -> Self {
        if newSize == columns.count {
            columns.removeAll(keepingCapacity: true)
        } else {
            columns.removeAll()
            columns.reserveCapacity(newSize)
        }
        
        rows.removeAll()
        return self
    }
    
    func eat(view: ANSIView, column: Int) {
        let usableWidth = usableWidth(forColumn: column)
        var compiled = [String]()
        var end: Int { 1 + compiled.count }
        view.dispatchWillRender(withWidth: usableWidth)
        
        func walk(view: ANSIView, start: Int) {
            compiled.append(contentsOf: view.rows.paint(toWidth: usableWidth))
            
            if view is ANSIViewCustomCompositing {
                return view.walk { view in
                    rows[ObjectIdentifier(view)] = (start, end)
                }
            }
            
            for subview in view.subviews {
                walk(view: subview, start: end) // on each call, end moves ahead by the previous views row count, marking the new start
            }
            
            rows[ObjectIdentifier(view)] = (start, end)
        }
        
        walk(view: view, start: end)
        
        columns[column, []] = compiled
    }
    
    func usableWidth(forColumn column: Int) -> Int {
        delegate.width(forColumn: column) - requiredWidth(forColumn: column)
    }
    
    func requiredWidth(forColumn column: Int) -> Int {
        guard let verticalBorder = verticalBorder else {
            return 0
        }
        
        switch column {
        case 0:
            return outsideBorder ? verticalBorder.count * 2 : 0
        case delegate.numberOfColumns() - 1:
            return outsideBorder ? verticalBorder.count : 0
        default:
            return verticalBorder.count
        }
    }
    
    func widthsBefore(column: Int) -> Int {
        var width = 0
        
        for col in 0..<column {
            width += delegate.width(forColumn: col)
        }
        
        return width
    }
    
    func rows(withWidth width: Int) -> [String] {
        if width == oldWidth, columns == oldColumns {
            return oldRender
        }
        
        var rows: [String] = []
        
        for (index, column) in columns.enumerated() {
            let lineWrapper = lineWrapper(forColumn: index)
            
            for (line, row) in column.enumerated() {
                rows[line, String(repeating: " ", count: widthsBefore(column: index))] += lineWrapper(row)
            }
        }
        
        oldRender = rows
        oldColumns = columns
        oldWidth = width
        
        return rows
    }
}

extension _ANSIColumnCompositor {
    @_transparent
    func lineWrapper(forColumn column: Int) -> (String) -> String {
        let usableWidth = usableWidth(forColumn: column)
        
        @_transparent
        var noop: (String) -> String {
            { $0.ensuring(length: usableWidth) }
        }
        
        guard let verticalBorder = verticalBorder else {
            return noop
        }
        
        switch column {
        case delegate.numberOfColumns() - 1:
            guard outsideBorder else {
                return noop
            }
            
            break
        case 0:
            guard outsideBorder else {
                break
            }
            
            return {
                var str = $0.ensuring(length: usableWidth).appending(verticalBorder)
                str.insert(contentsOf: verticalBorder, at: str.startIndex)
                return str
            }
        default:
            break
        }
        
        return { $0.ensuring(length: usableWidth).appending(verticalBorder) }
    }
}

// MARK: - Helpers

public enum StringPositioning {
    case left, right, center
    
    @inlinable func apply<Text: StringProtocol>(text: Text, width: Int) -> String {
        var ansiCount = 0
        let countWithoutANSI = ANSIAttr.count(textWithoutAttributes: text, ansiCount: &ansiCount)
        
        if countWithoutANSI > width {
            return String(text.prefix(width))
        } else if countWithoutANSI == width {
            return String(text)
        } else {
            switch self {
            case .left: return text.appending(String(repeating: " ", count: Swift.max(width - countWithoutANSI, 0)))
            case .center:
                let gap = max(width - countWithoutANSI, 0)
                let lw = Int(ceil(Double(gap) / 2)), rw = Int(floor(Double(gap) / 2))
                
                return String(repeating: " ", count: lw).appending(text).appending(String(repeating: " ", count: rw))
            case .right: return String(repeating: " ", count: Swift.max(width - countWithoutANSI, 0)).appending(text)
            }
        }
    }
}

public extension StringProtocol {
    @inlinable func ensuring(length: Int) -> String {
        var ansiCount = 0
        let countWithoutANSI = ANSIAttr.count(textWithoutAttributes: self, ansiCount: &ansiCount)
        
        if countWithoutANSI > length {
            return String(prefix(length + ansiCount))
        } else if countWithoutANSI == length {
            return String(self)
        } else {
            return appending(String(repeating: " ", count: Swift.max(length - countWithoutANSI, 0)))
        }
    }
}

private extension Array {
    subscript (index: Index, default: Element) -> Element {
        _modify {
            if index == endIndex {
                self.append(`default`)
            }
            
            yield &self[index]
        }
        _read {
            if !indices.contains(index) {
                yield `default`; return
            }
            
            yield self[index]
        }
    }
}
