//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/24/21.
//

import Foundation

public enum ANSIEscapeCode: UInt8 {
    case none      = 0    // null
    case up        = 65   // ESC [ A
    case down      = 66   // ESC [ B
    case right     = 67   // ESC [ C
    case left      = 68   // ESC [ D
    case end       = 70   // ESC [ F  or  ESC [ 4~
    case home      = 72   // ESC [ H  or  ESC [ 1~
    case insert    = 2    // ESC [ 2~
    case delete    = 3    // ESC [ 3~
    case pageUp    = 5    // ESC [ 5~
    case pageDown  = 6    // ESC [ 6~
    
    case f1        = 80   // ESC O P  or  ESC [ 11~
    case f2        = 81   // ESC O Q  or  ESC [ 12~
    case f3        = 82   // ESC O R  or  ESC [ 13~
    case f4        = 83   // ESC O S  or  ESC [ 14~
    case f5        = 15   // ESC [ 15~
    case f6        = 17   // ESC [ 17~
    case f7        = 18   // ESC [ 18~
    case f8        = 19   // ESC [ 19~
    case f9        = 20   // ESC [ 20~
    case f10       = 21   // ESC [ 21~
    case f11       = 23   // ESC [ 23~
    case f12       = 24   // ESC [ 24~
}

public enum ANSIModifierCode: UInt8 {
    case control = 1
    case shift   = 2
    case alt     = 3
}

public struct ANSIInputEvent {
    public var code: ANSIEscapeCode
    public var characters: [Character]
    public var modifiers: [ANSIModifierCode]
}

internal extension ANSIInputEvent {
    static func read() -> ANSIInputEvent {
        var event = ANSIInputEvent()
        var command = ESC
        
        let character = readChar()
        event.characters.append(character)
        command.append(character)
        
        switch command {
        case CSI: // CSI command
            let key = readCode()
            
            if isLetter(key) { // CSI + letter
                event.code = .csiLetter(rawValue: UInt8(key))
                break
            } else if isNumber(key) { // CSI + numbers
                command = String(Unicode.Scalar(key) ?? "\0") // collect numbers
                
                var char: Character
                
                repeat {
                    char = readChar() // char after number has been read
                    
                    if isNumber(char) {
                        command.append(character)
                    }
                } while isNumber(char)
                
                let number = Int(command)! // guaranteed valid number
                
                if char == ";" { // CSI + numbers + ;
                    command = String(readChar())
                    
                    if isNumber(command) {
                        event.modifiers = ANSIModifierCode.parse(key: UInt8(command)!)
                    }
                    
                    if number == 1 { // CSI + 1 + ; + meta
                        let key = readCode() // CSI + 1 + ; + meta + letter
                        
                        if isLetter(key) {
                            event.code = .csiLetter(rawValue: UInt8(key))
                        }
                    } else {
                        event.code = .csiNumber(rawValue: UInt8(number))
                        _ = readCode() // dismiss the tilde (guaranted)
                    }
                } else {
                    event.code = .csiNumber(rawValue: UInt8(number))
                }
            }
        case SS3:
            let key = readCode()
            
            if isLetter(key) {
                event.code = .ss3(rawValue: UInt8(key))
            }
        default:
            break
        }
        
        return event
    }
    
    private static func readChar() -> Character {
        var key: UInt8 = 0
        let res = Darwin.read(STDIN_FILENO, &key, 1)
        return res < 0 ? "\0" : Character(UnicodeScalar(key))
    }

    private static func readCode() -> Int {
        var key: UInt8 = 0
        let res = Darwin.read(STDIN_FILENO, &key, 1)
        return res < 0 ? 0 : Int(key)
    }
}

private extension ANSIEscapeCode {
    static func ss3(rawValue: UInt8) -> ANSIEscapeCode {
        switch rawValue {
        case f1.rawValue: return .f1
        case f2.rawValue: return .f2
        case f3.rawValue: return .f3
        case f4.rawValue: return .f4
        default: return .none
        }
    }
    
    static func csiLetter(rawValue: UInt8) -> ANSIEscapeCode {
        switch rawValue {
        case up.rawValue: return .up
        case down.rawValue: return .down
        case left.rawValue: return .left
        case right.rawValue: return .right
        case home.rawValue: return .home
        case end.rawValue: return .end
        case f1.rawValue: return .f1
        case f2.rawValue: return .f2
        case f3.rawValue: return .f3
        case f4.rawValue: return .f4
        default: return .none
        }
    }
    
    static func csiNumber(rawValue: UInt8) -> ANSIEscapeCode {
        switch rawValue {
        case 1: return .home
        case 4: return .end
        case insert.rawValue: return .insert
        case delete.rawValue: return .delete
        case pageUp.rawValue: return .pageUp
        case pageDown.rawValue: return .pageDown
        case 11: return .f1
        case 12: return .f2
        case 13: return .f3
        case 14: return .f4
        case f5.rawValue: return .f5
        case f6.rawValue: return .f6
        case f7.rawValue: return .f7
        case f8.rawValue: return .f8
        case f9.rawValue: return .f9
        case f10.rawValue: return .f10
        case f11.rawValue: return .f11
        case f12.rawValue: return .f12
        default: return .none
        }
    }
}

private extension ANSIModifierCode {
    static func parse(key: UInt8) -> [ANSIModifierCode] {
        switch key {
        case  2: return [.shift]                     // ESC [ x ; 2~
        case  3: return [.alt]                       // ESC [ x ; 3~
        case  4: return [.shift, .alt]               // ESC [ x ; 4~
        case  5: return [.control]                   // ESC [ x ; 5~
        case  6: return [.shift, .control]           // ESC [ x ; 6~
        case  7: return [.alt,   .control]           // ESC [ x ; 7~
        case  8: return [.shift, .alt,   .control]   // ESC [ x ; 8~
        default: return []
        }
    }
}

private extension ANSIInputEvent {
    init() {
        self.init(code: .none, characters: [], modifiers: [])
    }
}

@usableFromInline internal let ESC = "\u{1B}"  // Escape character (27 or 1B)
fileprivate let SS3 = ESC+"O"   // Single Shift Select of G3 charset
@usableFromInline internal let CSI = ESC+"["   // Control Sequence Introducer

@_transparent private func isLetter(_ key: Int) -> Bool {
    return (65...90 ~= key)
}

@_transparent private func isNumber(_ key: Int) -> Bool {
    return (48...57 ~= key)
}

@_transparent private func isNumber(_ chr: Character) -> Bool {
    return ("0"..."9" ~= chr)
}

@_transparent private func isNumber(_ str: String) -> Bool {
    return ("0"..."9" ~= str)
}
