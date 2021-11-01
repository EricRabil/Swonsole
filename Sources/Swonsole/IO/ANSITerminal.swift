//
//  ANSITerminal.swift
//
//  Bare-metal interface with the ANSI terminal
//  Kept internal to prevent misuse. Most APIs are exposed elsewhere
//
//  Created by Eric Rabil on 10/24/21.
//

import Foundation

internal protocol ANSITerminalDelegate {
    func terminal(_ terminal: ANSITerminal, receivedInput event: ANSIInputEvent)
}

public class ANSITerminal {
    public static let shared = ANSITerminal()
    
    private init() {
        source.setEventHandler {
            guard !self.processingCommand else {
                return
            }
            
            self.delegate?.terminal(self, receivedInput: .read())
        }
    }
    
    var delegate: ANSITerminalDelegate?
    public let source: DispatchSourceRead = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: .global(qos: .userInteractive))
    
    private var processingCommand = false
    private let lock = NSRecursiveLock()
    
    public func request(_ command: String, terminator: Character) -> String {
        lock.lock()
        processingCommand = true
        
        defer {
            processingCommand = false
            lock.unlock()
        }
        
        // send request
        write(command)

        // read response
        var res: String = ""
        var key: UInt8  = 0
        repeat {
            read(STDIN_FILENO, &key, 1)
            
            if key < 32 {
                res.append("^")  // replace non-printable ascii
            } else {
                res.append(Character(UnicodeScalar(key)))
            }
        } while key != terminator.asciiValue

        return res
    }
}

extension FileHandle: TextOutputStream {
  public func write(_ string: String) {
    self.write(Data(string.utf8))
  }
}

extension StringProtocol {
    @usableFromInline var dispatchData: DispatchData {
        Data(utf8).withUnsafeBytes {
            DispatchData(bytes: $0)
        }
    }
}

extension ANSITerminal {
    @usableFromInline static var stdout = FileHandle.standardOutput
    
    @_optimize(speed) @inlinable func write<Text: StringProtocol>(text: Text) {
        DispatchIO.write(toFileDescriptor: STDOUT_FILENO, data: text.dispatchData, runningHandlerOn: .global(qos: .userInteractive)) { _,_ in }
    }
    
    @_optimize(speed) @inlinable func write(_ text: String...) {
        for text in text {
            self.write(text: text)
        }
    }
}

// MARK: - Structure

extension ANSITerminal {
    func insertLine(_ row: Int = 1) {
        write(CSI,"\(row)L")
    }
    
    func deleteLine(_ row: Int = 1) {
        write(CSI,"\(row)M")
    }
    
    func deleteChar(_ char: Int = 1) {
        write(CSI,"\(char)P")
    }
    
    func enableReplaceMode() {
        write(CSI,"4l")
    }
    
    func disableReplaceMode() {
        write(CSI,"4h")
    }
}

// MARK: - Line Management

extension ANSITerminal {
    func clearBelow() {
        write(CSI,"0J")
    }
    
    func clearAbove() {
        write(CSI,"1J")
    }
    
    func clearScreen() {
        write(CSI,"2J",CSI,"H")
    }
    
    func clearToEndOfLine() {
        write(CSI,"0K")
    }
    
    func clearToStartOfLine() {
        write(CSI,"1K")
    }
    
    func clearLine() {
        write(CSI,"2K")
    }
}

// MARK: - Raw Mode

public extension ANSITerminal {
    static var defaultTerminal: termios = {
        var term = termios()
        
        tcgetattr(0, &term)
        
        return term
    }()
    
    func setRawMode() {
        var raw = termios()
        tcgetattr(0, &raw)
        
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON)
        tcsetattr(0, TCSAFLUSH, &raw)
    }
    
    func restoreInitialMode() {
        tcsetattr(0, TCSAFLUSH, &Self.defaultTerminal)
    }
}
