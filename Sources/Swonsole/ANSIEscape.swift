//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/8/21.
//

import Foundation

private let isTerminalApp = ProcessInfo.processInfo.environment["TERM_PROGRAM"] == "Apple_Terminal"

public struct ANSIEscape {
    public static let ESC = "\u{001B}["
    public static let OSC = "\u{001B}]"
    public static let BEL = "\u{0007}"
    public static let SEP = ";"
    
    public static func cursorTo(x: Int, y: Int? = nil) -> String {
        guard let y = y else {
            return ESC + (x + 1).description + "G"
        }
        
        return ESC + (y + 1).description + ";" + (x + 1).description + "H"
    }
    
    public static func cursorMove(x: Int, y: Int? = nil) -> String {
        var returnValue = ""
        
        if x < 0 {
            returnValue += ESC + (-x).description + "D"
        } else if x > 0 {
            returnValue += ESC + x.description + "C"
        }
        
        if let y = y {
            if y < 0 {
                returnValue += ESC + (-y).description + "A"
            } else if y > 0 {
                returnValue += ESC + y.description + "B"
            }
        }
        
        return returnValue
    }
    
    public static func cursorUp(count: Int = 1) -> String {
        ESC + count.description + "A"
    }
    
    public static func cursorDown(count: Int = 1) -> String {
        ESC + count.description + "B"
    }
    
    public static func cursorForward(count: Int = 1) -> String {
        ESC + count.description + "C"
    }
    
    public static func cursorBackward(count: Int = 1) -> String {
        ESC + count.description + "D"
    }
    
    public static let cursorLeft = ESC + "G"
    public static let cursorSavePosition = isTerminalApp ? "\u{001B7}" : (ESC + "s")
    public static let cursorRestorePosition = isTerminalApp ? "\u{001B8}" : (ESC + "u")
    public static let cursorGetPosition = ESC + "6n"
    public static let cusrorNextLine = ESC + "E"
    public static let cursorPrevLine = ESC + "F"
    public static let cursorHide = ESC + "?25l"
    public static let cursorShow = ESC + "?25h"
    
    public static func eraseLines(count: Int) -> String {
        var clear = ""
        
        for i in 0..<count {
            clear += eraseLine + (i < (count - 1) ? cursorUp() : "")
        }
        
        return clear
    }
    
    public static let eraseEndLine = ESC + "K"
    public static let eraseStartLine = ESC + "1K"
    public static let eraseLine = ESC + "2K"
    public static let eraseDown = ESC + "J"
    public static let eraseUp = ESC + "1J"
    public static let eraseScreen = ESC + "2J"
    public static let scrollUp = ESC + "S"
    public static let scrollDown = ESC + "T"
    
    public static let clearScreen = "\u{001Bc}"
    
    public static let clearTerminal = eraseScreen + ESC + "3J" + ESC + "H"
    public static let beep = BEL
    
    public static func link(text: String, url: String) -> String {
        return [
            OSC,
            "8",
            SEP,
            SEP,
            url,
            BEL,
            text,
            OSC,
            "8",
            SEP,
            SEP,
            BEL
        ].joined(separator: "")
    }
}
