//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/29/21.
//

import Foundation

public enum ANSIEffect: UInt8, CaseIterable {
    case normal         = 0
    case bold           = 1
    case dim            = 2
    case italic         = 3
    case underline      = 4
    case blink          = 5
    case overline       = 6
    case inverse        = 7
    case hidden         = 8
    case strike         = 9
    case noBold         = 21
    case noDim          = 22
    case noItalic       = 23
    case noUnderline    = 24
    case noBlink        = 25
    case noOverline     = 26
    case noInverse      = 27
    case noHidden       = 28
    case noStrike       = 29
    
    public var effectString: String {
        Self.effectStringTable[self]!
    }
}

internal extension ANSIEffect {
    @usableFromInline static let effectStringTable = allCases.buildDict {
        ($0, CSI + $0.rawValue.description + "m")
    }
}
