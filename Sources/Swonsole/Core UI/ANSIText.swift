//
//  ANSIText.swift
//
//  Provides a mechanism for rendering flexible, styled text
//
//  Created by Eric Rabil on 10/24/21.
//

import Foundation

private let RESET = CSI + "0m" + CSI + "39m"

// Repeats a given character for whatever render width it is given
open class ANSIHorizontalBorder: ANSINode {
    open var character: Character
    
    public init(character: Character) {
        self.character = character
        super.init()
    }
    
    open override func render(withWidth width: Int) -> [String] {
        [String(repeating: character, count: width)]
    }
}

// A set of text groups
open class ANSITextGroup: ANSINode, ANSINodeCustomCompositing {
    open override func render(withWidth width: Int) -> [String] {
        let rules: [ANSIHorizontalRule] = children.compactMap {
            ($0 as! ANSIText)
        }.map { textNode in
            ANSIHorizontalRule.fixed(width: textNode.text.count)
        } + [.flex]
        
        return rules.render(withWidth: width) { index, width in
            if index == children.count {
                return ANSIRenderNode(ANSIText.recycledNode(forNode: self, index: 0), withWidth: width)
            } else {
                return ANSIRenderNode(children[index], withWidth: width)
            }
        }
    }
}

open class ANSIText: ANSINode, ExpressibleByStringLiteral {
    public struct Style {
        public static let `default` = Style(positioning: .left)
        
        public init(positioning: ANSIStringPositioning, color: ANSIColor? = nil, backgroundColor: ANSIColor? = nil, effects: [ANSIEffect]? = nil) {
            self.positioning = positioning
            self.color = color
            self.backgroundColor = backgroundColor
            self.effects = effects
        }
        
        public var positioning: ANSIStringPositioning
        public var color: ANSIColor?
        public var backgroundColor: ANSIColor?
        public var effects: [ANSIEffect]?
    }
    
    public var style: Style = Style(positioning: .left)
    
    public var text: String
    
    public required init(stringLiteral value: String) {
        self.text = value
        super.init()
    }
    
    public convenience init(text: String) {
        self.init(stringLiteral: text)
    }
    
    public override convenience init() {
        self.init(stringLiteral: "")
    }
    
    @inlinable public func withText(_ text: String) -> Self {
        self.text = text
        return self
    }
    
    open override func render(withWidth width: Int) -> [String] {
        if text.count == 0 {
            return [String.spaces(repeating: width)]
        }
        
        return [style.wrap(text: style.positioning.apply(text: text, width: width))]
    }
}

private extension ANSIText.Style {
    @_transparent @_optimize(speed) func wrap(text: String) -> String {
        var text = text
        
        if let effects = effects {
            text = effects.map(\.effectString).joined() + text
        }
        
        if let backgroundColor = backgroundColor {
            text = backgroundColor.backgroundString + text
        }
        
        if let color = color {
            text = color.textString + text
        }
        
        return text + RESET
    }
}

internal extension Collection {
    func buildDict<Key: Hashable, Value>(_ mapper: (Element) -> (Key, Value)) -> [Key: Value] {
        map(mapper).reduce(into: [:]) { dict, entry in
            dict[entry.0] = entry.1
        }
    }
}
