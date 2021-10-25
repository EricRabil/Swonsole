//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/17/21.
//

import Foundation

extension Array {
    func buildDict<Key: Hashable, Value>(_ mapper: (Element) -> (Key, Value)) -> [Key: Value] {
        map(mapper).reduce(into: [:]) { dict, entry in
            dict[entry.0] = entry.1
        }
    }
}

internal extension Array {
    @inlinable func collect(_ mapper: (Element) -> Int) -> Int {
        reduce(0) { $0 + mapper($1) }
    }
}

private let reset = ANSIAttr.default.description + ANSIAttr.onDefault.description

open class ANSIPaintableHost: ANSIView {
    open var rows: [Paintable] = []
    
    public init(_ rows: Paintable...) {
        self.rows = rows
    }
    
    public init(rows: [Paintable] = []) {
        self.rows = rows
    }
}

public struct StyledText: Paintable, ExpressibleByStringLiteral {
    public var rawText: () -> String
    public var attributes: [ANSIAttr]
    public var positioning: StringPositioning
    
    public init(text: String, attributes: [ANSIAttr] = [], positioning: StringPositioning = .left) {
        self.rawText = { text }
        self.attributes = attributes
        self.positioning = positioning
    }
    
    public init(dynamicText: @autoclosure @escaping () -> String, attributes: [ANSIAttr] = [], positioning: StringPositioning = .left) {
        self.rawText = dynamicText
        self.attributes = attributes
        self.positioning = positioning
    }
    
    public init(stringLiteral value: String) {
        self.init(text: value)
    }
    
    private static let counts: [ANSIAttr: Int] = (
        ANSIAttr.allCases.buildDict {
            ($0, $0.style("").count)
        }
    )
    
    public func paint(toWidth width: Int) -> [String] {
        var text = positioning.apply(text: rawText(), width: width)
        
        for attribute in attributes {
            text = attribute.description + text
        }
        
        return [
            reset + text + reset
        ]
    }
}

public extension StyledText {
    @inlinable var left: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes, positioning: .left)
    }
    @inlinable var center: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes, positioning: .center)
    }
    @inlinable var right: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes, positioning: .right)
    }
}

public extension StyledText {
    @inlinable var normal: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.normal], positioning: positioning)
    }
    @inlinable var bold: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.bold], positioning: positioning)
    }
    @inlinable var dim: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.dim], positioning: positioning)
    }
    @inlinable var italic: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.italic], positioning: positioning)
    }
    @inlinable var underline: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.underline], positioning: positioning)
    }
    @inlinable var blink: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.blink], positioning: positioning)
    }
    @inlinable var overline: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.overline], positioning: positioning)
    }
    @inlinable var inverse: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.inverse], positioning: positioning)
    }
    @inlinable var hidden: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.hidden], positioning: positioning)
    }
    @inlinable var strike: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.strike], positioning: positioning)
    }
    @inlinable var noBold: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.noBold], positioning: positioning)
    }
    @inlinable var noDim: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.noDim], positioning: positioning)
    }
    @inlinable var noItalic: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.noItalic], positioning: positioning)
    }
    @inlinable var noUnderline: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.noUnderline], positioning: positioning)
    }
    @inlinable var noBlink: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.noBlink], positioning: positioning)
    }
    @inlinable var noOverline: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.noOverline], positioning: positioning)
    }
    @inlinable var noInverse: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.noInverse], positioning: positioning)
    }
    @inlinable var noHidden: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.noHidden], positioning: positioning)
    }
    @inlinable var noStrike: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.noStrike], positioning: positioning)
    }
    @inlinable var black: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.black], positioning: positioning)
    }
    @inlinable var red: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.red], positioning: positioning)
    }
    @inlinable var green: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.green], positioning: positioning)
    }
    @inlinable var brown: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.brown], positioning: positioning)
    }
    @inlinable var blue: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.blue], positioning: positioning)
    }
    @inlinable var magenta: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.magenta], positioning: positioning)
    }
    @inlinable var cyan: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.cyan], positioning: positioning)
    }
    @inlinable var gray: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.gray], positioning: positioning)
    }
    @inlinable var fore256Color: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.fore256Color], positioning: positioning)
    }
    @inlinable var `default`: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.default], positioning: positioning)
    }
    @inlinable var darkGray: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.darkGray], positioning: positioning)
    }
    @inlinable var lightRed: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.lightRed], positioning: positioning)
    }
    @inlinable var lightGreen: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.lightGreen], positioning: positioning)
    }
    @inlinable var yellow: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.yellow], positioning: positioning)
    }
    @inlinable var lightBlue: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.lightBlue], positioning: positioning)
    }
    @inlinable var lightMagenta: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.lightMagenta], positioning: positioning)
    }
    @inlinable var lightCyan: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.lightCyan], positioning: positioning)
    }
    @inlinable var white: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.white], positioning: positioning)
    }
    @inlinable var onBlack: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onBlack], positioning: positioning)
    }
    @inlinable var onRed: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onRed], positioning: positioning)
    }
    @inlinable var onGreen: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onGreen], positioning: positioning)
    }
    @inlinable var onBrown: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onBrown], positioning: positioning)
    }
    @inlinable var onBlue: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onBlue], positioning: positioning)
    }
    @inlinable var onMagenta: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onMagenta], positioning: positioning)
    }
    @inlinable var onCyan: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onCyan], positioning: positioning)
    }
    @inlinable var onGray: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onGray], positioning: positioning)
    }
    @inlinable var back256Color: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.back256Color], positioning: positioning)
    }
    @inlinable var onDefault: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onDefault], positioning: positioning)
    }
    @inlinable var onDarkGray: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onDarkGray], positioning: positioning)
    }
    @inlinable var onLightRed: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onLightRed], positioning: positioning)
    }
    @inlinable var onLightGreen: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onLightGreen], positioning: positioning)
    }
    @inlinable var onYellow: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onYellow], positioning: positioning)
    }
    @inlinable var onLightBlue: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onLightBlue], positioning: positioning)
    }
    @inlinable var onLightMagenta: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onLightMagenta], positioning: positioning)
    }
    @inlinable var onLightCyan: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onLightCyan], positioning: positioning)
    }
    @inlinable var onWhite: StyledText {
        StyledText(dynamicText: rawText(), attributes: attributes + [.onWhite], positioning: positioning)
    }
}
