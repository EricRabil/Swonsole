//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/9/21.
//

import Foundation

extension _ANSIScreenInterface {
    var rowsBelowCursor: Int {
        readScreenSize().row - currentRow
    }
    
    var currentRow: Int {
        readCursorPos().row
    }
}

protocol Clashable: AnyObject, Hashable {}

extension Clashable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}

extension Weak: Equatable where T: Equatable {
    static func ==(lhs: Weak<T>, rhs: Weak<T>) -> Bool {
        lhs.value === rhs.value
    }
}

extension Weak: Hashable where T: Hashable {
    func hash(into hasher: inout Hasher) {
        value?.hash(into: &hasher)
    }
}

public extension _ANSIScreenInterface {
    private(set) static var screenRows: Int = 0
    private(set) static var screenColumns: Int = 0
    
    var screenRows: Int { Self.screenRows }
    var screenColumns: Int { Self.screenColumns }
}

internal extension _ANSIScreenInterface {
    private static func refresh() {
        (screenRows, screenColumns) = ANSIScreen.readScreenSize()
    }
    
    private static var didRegisterWinch = false
    static func registerIfNeeded() {
        if !didRegisterWinch {
            didRegisterWinch = true
            
            signal(SIGWINCH) { _ in
                _ANSIScreenInterface.refresh()
            }
            
            refresh()
        }
    }
}

// Raw row renderer, manages spacing and writing to the terminal
public class ANSIRenderer: Clashable {
    public static let shared: ANSIRenderer = {
        _ANSIScreenInterface.registerIfNeeded()
        
        return ANSIRenderer()
    }()
    
    public private(set) var pointer = ANSIScreen.currentRow // row of the top of the render
    
    // Sets the pointer to the current ANSI cursor row
    // Please don't call this unless you're trying to rebuild state
    internal func resetPointer() {
        pointer = ANSIScreen.currentRow
    }
    
    private func pointer(offsetBy offset: Int) -> Int {
        min(pointer + offset, ANSIScreen.screenRows)
    }
    
    private var rowsBelowPointer: Int { // free space below current pointer
        max(ANSIScreen.screenRows - pointer, 0)
    }
    
    // ensures there is enough space in the terminal if there arent enough lines
    // prints additional lines if we are at the bottom and out of room
    private func nudgePointer(count neededRows: Int) {
        if rowsBelowPointer >= neededRows {
            return // we have enough rows
        }
        
        let missingRows = neededRows - rowsBelowPointer
        
        for _ in (0..<missingRows) {
            ANSITerminal.write("\n")
        }
        
        pointer = ANSIScreen.screenRows - neededRows // set pointer to n rows from bottom
        needsTrash = true
    }
    
    // number of rows of the last render
    private var previousRows: [String] = []
    private var previousRange: Range<Int> {
        previousRows.indices
    }
    
    // shifts lastTop down the number of rows of the last render
    // missing rows will be created next render
    public func shift(by offset: Int? = nil) {
        pointer = pointer(offsetBy: offset ?? previousRows.count)
        needsTrash = true
    }
    
    // signal that the next render should re-print every row regardless of whether they changed
    // useful to fix the terminal in-place after a resize
    public var needsTrash = false
    
    // render a set of lines to the terminal in the configured position
    public func render(lines: [String]) {
        nudgePointer(count: lines.count)
        
        for (index, line) in lines.enumerated() {
            if !needsTrash, previousRange.contains(index) && previousRows[index] == line {
                continue
            }
            
            ANSIScreen.moveTo(pointer(offsetBy: index), 0)
            ANSIScreen.clearLine()
            ANSITerminal.write(line)
        }
        
        ANSIScreen.moveTo(pointer(offsetBy: lines.count), 0)
        needsTrash = false
        
        previousRows = lines
    }
}
