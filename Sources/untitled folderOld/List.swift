//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/8/21.
//

import Foundation

class TextField {
    var text: String = "rawr"
    var position = 1 {
        didSet {
            if position < 1 {
                position = text.count
            } else if position > text.count + 1 {
                position = 1
            }
        }
    }
    
    private var absolutePosition: Int {
        position - 1
    }
    
    func remove(at position: Int) {
        guard position > -1, position < text.count else {
            return
        }
        
        let index = text.index(text.startIndex, offsetBy: position)
        
        guard text.indices.contains(index) else {
            return
        }
        
        text.remove(at: index)
    }
    
    func delete() {
        remove(at: absolutePosition)
    }
    
    func backspace() {
        remove(at: absolutePosition - 1)
        
        if position > 1 {
            position -= 1
        }
    }
    
    func insert(character: Character) {
        text.insert(character, at: text.index(text.startIndex, offsetBy: absolutePosition))
        position += 1
    }
    
    func left() {
        position -= 1
    }
    
    func right() {
        position += 1
    }
    
    func render() {
        write("\n", text)
    }
}

public class List<Element: CustomStringConvertible> {
    private let reader = InputReader(fileDescriptor: STDIN_FILENO)
    private let renderer: ListRenderer<Element>
    
    public var filterText: String = ""
    
    let textField = TextField()
    
    public init(_ items: [Element], options: ListRenderer<Element>.Options = .init()) {
        renderer = ListRenderer(items: items, options: options)
        
        reader.setEventHandler(handler: handle(code:meta:chars:))
    }
    
    public func resume() {
        reader.resume()
        InputReader.enableRawMode(fileHandle: .standardInput)
        
        render()
    }
    
    private var dimensions: (rows: Int, cols: Int) {
        var w = winsize()
        
        let _ = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
        
        return (Int(w.ws_row), Int(w.ws_col))
    }
    
    private var firstRun = true
    
    private func render() {
        let spaceNeeded = renderer.rows + 1
        var neededRows: Int = max(0, spaceNeeded - (dimensions.rows - readCursorPos().row))
        
        if firstRun {
            firstRun = false
            if neededRows == 0 {
                moveDown(spaceNeeded - 1)
            } else {
                if neededRows == spaceNeeded {
                    neededRows -= 1
                }
                
                for _ in 0..<neededRows {
                    print()
                }
            }
        }
        
        write(ANSIEscape.eraseLines(count: spaceNeeded))
        moveToColumn(0)
        renderer.render()
        textField.render()
        moveToColumn(textField.position)
    }
    
    private func handle(code: ANSIKeyCode, meta: [ANSIMetaCode], chars: [Character]) {
        if chars.contains("\u{1B}") {
            return
        }
        
        InputReader.restoreRawMode(fileHandle: .standardInput)
        switch code {
        case .up:
            renderer.activeIndex -= 1
        case .down:
            renderer.activeIndex += 1
        case .left:
            textField.left()
        case .right:
            textField.right()
        default:
            for char in chars {
                switch char {
                case "\u{1B}":
                    break
                case "\r":
                    fallthrough
                case "\n":
                    renderer.toggleActiveSelection()
                case "\u{7F}": // backspace
                    textField.backspace()
                case "\u{04}": // delete
                    textField.delete()
                default:
                    textField.insert(character: char)
                }
            }
        }
        
        render()
        InputReader.enableRawMode(fileHandle: .standardInput)
    }
}
