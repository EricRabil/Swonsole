//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/24/21.
//

import Foundation

public class ANSICursor {
    public static let shared = ANSICursor()

    private init() {}
    
    private var suppressUpdates = false
    public var coordinates: (x: Int, y: Int) {
        get {
            readCursorPos()
        }
        set {
            moveTo(newValue.y, newValue.x)
        }
    }
    
    @usableFromInline let terminal = ANSITerminal.shared
}

public extension ANSICursor {
    @inlinable func moveTo(_ row: Int, _ col: Int) {
        terminal.write(CSI + "\(row);\(col)H")
    }
}

// MARK: - Raw cursor APIs

private func readCursorPos() -> (x: Int, y: Int) {
    let str = ANSITerminal.shared.request(CSI+"6n", terminator: "R")  // returns ^[row;colR
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
    
    return (col, row)
}

// MARK: - State

public extension ANSICursor {
    enum CursorStyle: UInt8 {
      case block = 1
      case line  = 3
      case bar   = 5
    }
    
    func cursorOff() {
        terminal.write(CSI,"?25l")
    }
    
    func cursorOn() {
        terminal.write(CSI,"?25h")
    }
    
    func storeCursorPosition(isANSI: Bool = true) {
        if isANSI {
            terminal.write(CSI,"s")
        } else {
            terminal.write(ESC,"7")
        }
    }
    
    func restoreCursorPosition(isANSI: Bool = false) {
        if isANSI {
            terminal.write(CSI,"u")
        } else {
            terminal.write(ESC,"8")
        }
    }
    
    func setCursorStyle(_ style: CursorStyle, blinking: Bool = true) {
        if blinking {
            terminal.write(CSI+"\(style.rawValue) q")
        } else {
            terminal.write(CSI+"\(style.rawValue + 1) q")
        }
    }
}
