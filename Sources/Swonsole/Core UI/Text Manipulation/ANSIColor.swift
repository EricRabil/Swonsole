//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/29/21.
//

import Foundation

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

public extension ANSIColor {
    @_transparent var textString: String {
        Self.textStringTable[self]!
    }
    
    @_transparent var backgroundString: String {
        Self.bgStringTable[self]!
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
