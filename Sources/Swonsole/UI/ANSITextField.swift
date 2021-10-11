//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/9/21.
//

import Foundation

public protocol ANSITextFieldDelegate: ANSIViewDelegate {
    func textField(_ field: ANSITextField, valueChanged value: String)
}

public extension ANSITextFieldDelegate {
    func textField(_ field: ANSITextField, valueChanged value: String) {}
}

extension String {
    static func += (lhs: inout String, rhs: Character) {
        lhs.insert(rhs, at: lhs.endIndex)
    }
}

private extension String {
    mutating func remove(position: Int) {
        let index = index(startIndex, offsetBy: position)
        guard indices.contains(index) else {
            return
        }
        
        remove(at: index)
    }
}

public class ANSITextField: ANSIViewDelegating {
    public var value: String
    public var placeholder: String?
    public var prefix: String?
    public var suffix: String?
    
    public private(set) var position = 0
    public var delegate: ANSITextFieldDelegate?
    
    private var index: String.Index { value.index(value.startIndex, offsetBy: position) }
    private var indexBefore: String.Index? {
        let index = index
        
        guard index != value.startIndex, value.indices.contains(index) || index == value.endIndex else {
            return nil
        }
        
        return value.index(before: index)
    }
    
    private lazy var formatter = ANSIStringFormatter(field: self)
    
    @discardableResult
    private func removePrevious() -> Bool {
        guard let indexBefore = indexBefore else {
            return false
        }
        
        value.remove(at: indexBefore)
        left()
        return true
    }
    
    public init(initialValue: String = "", delegate: ANSITextFieldDelegate? = nil) {
        value = initialValue
        self.delegate = delegate
    }
    
    public var rows: [String] {
        [formatter.formattedText]
    }
    
    public func left() {
        if self.position <= 0 {
            self.position = self.value.count
        } else {
            self.position -= 1
        }
    }
    
    public func right() {
        if self.position >= self.value.count {
            self.position = 0
        } else {
            self.position += 1
        }
    }
    
    public var active: Bool {
        get { sourceConnection.active }
        set {
            sourceConnection.active = newValue
            
            if newValue {
                ANSIScreen.cursorOn()
            } else {
                ANSIScreen.cursorOff()
            }
        }
    }
    
    private lazy var sourceConnection = ANSISourceConnection(handle(payload:))
    
    public func handle(payload: ANSIPayload) {
        switch payload.code {
        case .left:
            left()
        case .right:
            right()
        case .none:
            for char in payload.chars {
                switch char {
                case "\u{1B}":
                    break
                case NonPrintableChar.del.rawValue:
                    guard value.count > 0 else {
                        break
                    }
                    
                    if removePrevious() {
                        delegate?.textField(self, valueChanged: value)
                    }
                case "\r":
                    fallthrough
                case "\n":
                    break
                default:
                    value.insert(char, at: index)
                    right()
                    delegate?.textField(self, valueChanged: value)
                }
            }
        default:
            break
        }
    }
    
    public func rendered(toRows rows: [Int]) {
        if active {
            if let row = rows.first {
                ANSIScreen.moveTo(row, formatter.cursorPosition)
            } else {
                ANSIScreen.moveToColumn(formatter.cursorPosition)
            }
            
            ANSIScreen.cursorOn()
        }
    }
    
    public func unmounted() {
        active = false
    }
}
