//
//  ANSIText.swift
//
//  Provides a mechanism for rendering flexible, styled text
//
//  Created by Eric Rabil on 10/24/21.
//

import Foundation

private let RESET = CSI + "0m" + CSI + "39m"

open class ANSIText: ANSINode {
    public var positioning: StringPositioning = .left
    public var backgroundColor: ANSIColor?
    public var color: ANSIColor?
    
    public var text: String?
    
    public convenience init(text: String) {
        self.init()
        self.text = text
    }
    
    public func colored(by color: ANSIColor?) -> Self {
        self.color = color
        return self
    }
    
    public func backgrounded(by color: ANSIColor?) -> Self {
        self.backgroundColor = color
        return self
    }
    
    public func positioned(by positioning: StringPositioning?) -> Self {
        self.positioning = positioning ?? .left
        return self
    }
    
    private func wrap(text: String) -> String {
        var text = text
        
        if let backgroundColor = backgroundColor {
            text = backgroundColor.backgroundString + text
        }
        
        if let color = color {
            text = color.textString + text
        }
        
        return text + RESET
    }
    
    open override func render(withWidth width: Int) -> [String] {
        [wrap(text: positioning.apply(text: text ?? "", width: width))]
    }
}

public enum ANSIColor: CaseIterable {
    case black
    case red
    case green
    case brown
    case blue
    case magenta
    case cyan
    case gray
    case xcolor // 256 color
    case `default`
    case darkGray
    case lightRed
    case lightGreen
    case yellow
    case lightBlue
    case lightMagenta
    case lightCyan
    case white
}

public enum StringPositioning {
    case left, right, center
}

public extension ANSIColor {
    @_transparent var textString: String {
        Self.textStringTable[self]!
    }
    
    @_transparent var backgroundString: String {
        Self.bgStringTable[self]!
    }
}

public extension StringPositioning {
    func apply<Text: StringProtocol>(text: Text, width: Int) -> String {
        let count = text.count
        
        if count > width {
            return String(text.prefix(width))
        } else if count == width {
            return String(text)
        } else {
            switch self {
            case .left: return text.appending(String(repeating: " ", count: Swift.max(width - count, 0)))
            case .center:
                let gap = max(width - count, 0)
                let lw = Int(ceil(Double(gap) / 2)), rw = Int(floor(Double(gap) / 2))
                
                return String(repeating: " ", count: lw).appending(text).appending(String(repeating: " ", count: rw))
            case .right: return String(repeating: " ", count: Swift.max(width - count, 0)).appending(text)
            }
        }
    }
}

private extension Collection {
    func buildDict<Key: Hashable, Value>(_ mapper: (Element) -> (Key, Value)) -> [Key: Value] {
        map(mapper).reduce(into: [:]) { dict, entry in
            dict[entry.0] = entry.1
        }
    }
}

internal extension ANSIColor {
    @usableFromInline static let textStringTable = allCases.buildDict {
        ($0, CSI + $0.textCode.description + "m")
    }
    
    @usableFromInline static let bgStringTable = allCases.buildDict {
        ($0, CSI + $0.bgCode.description + "m")
    }
}

private extension ANSIColor {
    var textCode: Int {
        switch self {
        case .black:
            return 30
        case .red:
            return 31
        case .green:
            return 32
        case .brown:
            return 33
        case .blue:
            return 34
        case .magenta:
            return 35
        case .cyan:
            return 36
        case .gray:
            return 37
        case .xcolor:
            return 38
        case .default:
            return 39
        case .darkGray:
            return 90
        case .lightRed:
            return 91
        case .lightGreen:
            return 92
        case .yellow:
            return 93
        case .lightBlue:
            return 94
        case .lightMagenta:
            return 95
        case .lightCyan:
            return 96
        case .white:
            return 97
        }
    }
    
    var bgCode: Int {
        switch self {
        case .black:
            return 40
        case .red:
            return 41
        case .green:
            return 42
        case .brown:
            return 43
        case .blue:
            return 44
        case .magenta:
            return 45
        case .cyan:
            return 46
        case .gray:
            return 47
        case .xcolor:
            return 48
        case .default:
            return 49
        case .darkGray:
            return 100
        case .lightRed:
            return 101
        case .lightGreen:
            return 102
        case .yellow:
            return 103
        case .lightBlue:
            return 104
        case .lightMagenta:
            return 105
        case .lightCyan:
            return 106
        case .white:
            return 107
        }
    }
}
