//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/9/21.
//

import Foundation

public class _ANSIScreenInterface {
    public private(set) var isCursorVisible = false
    public private(set) var isReplacingMode = false
    
    public var terminal: _ANSITerminalInterface {
        ANSITerminal
    }
}

// MARK: - Clearing

public extension _ANSIScreenInterface {
    func clearBelow() {
        terminal.write(CSI,"0J")
    }
    
    func clearAbove() {
        terminal.write(CSI,"1J")
    }
    
    func clearScreen() {
        terminal.write(CSI,"2J",CSI,"H")
    }
    
    func clearToEndOfLine() {
        terminal.write(CSI,"0K")
    }
    
    func clearToStartOfLine() {
        terminal.write(CSI,"1K")
    }
    
    func clearLine() {
        terminal.write(CSI,"2K")
    }
}

// MARK: - Positioning

public extension _ANSIScreenInterface {
    func readCursorPos() -> (row: Int, col: Int) {
        let str = terminal.request(CSI+"6n", endChar: "R")  // returns ^[row;colR
        if str.isEmpty { return (-1, -1) }
        
        guard let esc = str.firstIndex(of: "["),
              let del = str.firstIndex(of: ";"),
              let end = str.firstIndex(of: "R"),
              str.index(after: del) != end else {
              return readCursorPos()
              }
        
        guard let row = Int(String(str[str.index(after: esc)...str.index(before: del)])),
              let col = Int(String(str[str.index(after: del)...str.index(before: end)])) else {
                  return readCursorPos()
              }
        
        return (row, col)
    }
    
    //! WARNING: 18t only works on a real terminal console, *not* on emulation.
    func readScreenSize() -> (row: Int, col: Int) {
        var w = winsize()
        
        let _ = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
        
        return (Int(w.ws_row), Int(w.ws_col))
    }
}

// MARK: - Repositioning

public extension _ANSIScreenInterface {
    func moveUp(_ row: Int = 1) {
        terminal.write(CSI,"\(row)A")
    }
    
    func moveDown(_ row: Int = 1) {
        terminal.write(CSI,"\(row)B")
    }
    
    func moveRight(_ col: Int = 1) {
        terminal.write(CSI,"\(col)C")
    }
    
    func moveLeft(_ col: Int = 1) {
        terminal.write(CSI,"\(col)D")
    }
    
    func moveLineDown(_ row: Int = 1) {
        terminal.write(CSI,"\(row)E")
    }
    
    func moveLineUp(_ row: Int = 1) {
        terminal.write(CSI,"\(row)F")
    }
    
    func moveToColumn(_ col: Int) {
        terminal.write(CSI,"\(col)G")
    }
    
    func moveTo(_ row: Int, _ col: Int) {
        terminal.write(CSI + "\(row);\(col)H")
    }
}

// MARK: - Structure

public extension _ANSIScreenInterface {
    func insertLine(_ row: Int = 1) {
        terminal.write(CSI,"\(row)L")
    }
    
    func deleteLine(_ row: Int = 1) {
        terminal.write(CSI,"\(row)M")
    }
    
    func deleteChar(_ char: Int = 1) {
        terminal.write(CSI,"\(char)P")
    }
}

// MARK: - State

public extension _ANSIScreenInterface {
    enum CursorStyle: UInt8 {
      case block = 1
      case line  = 3
      case bar   = 5
    }

    func enableReplaceMode() {
        terminal.write(CSI,"4l")
        isReplacingMode = true
    }
    
    func disableReplaceMode() {
        terminal.write(CSI,"4h")
        isReplacingMode = false
    }
    
    func cursorOff() {
        terminal.write(CSI,"?25l")
        isCursorVisible = false
    }
    
    func cursorOn() {
        terminal.write(CSI,"?25h")
        isCursorVisible = true
    }
    
    func scrollRegion(top: Int, bottom: Int) {
        terminal.write(CSI,"\(top);\(bottom)r")
    }
    
    func storeCursorPosition(isANSI: Bool = true) {
        if isANSI { terminal.write(CSI,"s") } else { terminal.write(ESC,"7") }
    }
    
    func restoreCursorPosition(isANSI: Bool = false) {
        if isANSI { terminal.write(CSI,"u") } else { terminal.write(ESC,"8") }
    }
    
    func setCursorStyle(_ style: CursorStyle, blinking: Bool = true) {
        if blinking { terminal.write(CSI+"\(style.rawValue) q") }
        else { terminal.write(CSI+"\(style.rawValue + 1) q") }
    }
}

public let ANSIScreen = _ANSIScreenInterface()
