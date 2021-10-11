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

public class ANSIRenderer {
    public static let shared = ANSIRenderer()
    
    public private(set) var lastTop = ANSIScreen.currentRow
    
    public var terminal: _ANSITerminalInterface {
        ANSITerminal
    }
    
    public var screen: _ANSIScreenInterface {
        ANSIScreen
    }
    
    public var availableRows: Int {
        (screen.readScreenSize().row - lastTop) + 1
    }
    
    func ensureRows(count: Int) {
        let availableRows = availableRows
        
        if availableRows >= count {
            return
        }
        
        let neededRows = count - availableRows
        
        for _ in (0..<neededRows) {
            print()
        }
        
        lastTop -= neededRows
    }
    
    func rowsFromTop(count: Int) -> [Int] {
        Array(lastTop...(lastTop + count))
    }
    
    private var previous: [String]? = nil
    private var offsetGap: Int? = nil
    
    public func shift() {
        guard let previous = previous else {
            return
        }
        
        let rawOffset = lastTop + previous.count, rows = ANSIScreen.readScreenSize().row
        
        lastTop = min(rows, rawOffset)
        offsetGap = rawOffset > rows ? rawOffset - rows : 0
        
        self.previous = nil
    }
    
    public var needsTrash = false
    
    public func render(lines: [String]) {
        if let offsetGap = offsetGap {
            for _ in 0..<offsetGap {
                print()
            }
            
            self.offsetGap = nil
        }
        
        ensureRows(count: lines.count)
        
        for (index, line) in lines.enumerated() {
            if previous?.indices.contains(index) == true, previous?[index] == line {
                if !needsTrash {
                    continue
                }
            }
            
            ANSIScreen.moveTo(lastTop + index, 0)
            ANSIScreen.clearLine()
            ANSITerminal.write(line)
        }
        
        ANSIScreen.moveTo(lastTop + lines.count, 0)
        needsTrash = false
        
        previous = lines
    }
}
