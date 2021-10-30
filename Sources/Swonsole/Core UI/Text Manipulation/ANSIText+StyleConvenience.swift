//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/29/21.
//

import Foundation

public extension ANSIText {
    var effects: [ANSIEffect]? {
        _read {
            yield style.effects
        }
        _modify {
            yield &style.effects
        }
    }
    
    var positioning: ANSIStringPositioning {
        _read {
            yield style.positioning
        }
        _modify {
            yield &style.positioning
        }
    }
    
    var color: ANSIColor? {
        _read {
            yield style.color
        }
        _modify {
            yield &style.color
        }
    }
    
    var backgroundColor: ANSIColor? {
        _read {
            yield style.backgroundColor
        }
        _modify {
            yield &style.backgroundColor
        }
    }
    
    func colored(by color: ANSIColor?) -> Self {
        style.color = color
        return self
    }
    
    func backgrounded(by color: ANSIColor?) -> Self {
        style.backgroundColor = color
        return self
    }
    
    func styled(by effects: [ANSIEffect]?) -> Self {
        style.effects = effects
        return self
    }
    
    func positioned(by positioning: ANSIStringPositioning?) -> Self {
        style.positioning = positioning ?? .left
        return self
    }
}

public extension ANSIText.Style {
    func colored(by color: ANSIColor?) -> Self {
        var style = self
        style.color = color
        return style
    }
    
    func backgrounded(by color: ANSIColor?) -> Self {
        var style = self
        style.backgroundColor = color
        return style
    }
    
    func styled(by effects: [ANSIEffect]?) -> Self {
        var style = self
        style.effects = effects
        return style
    }
    
    func positioned(by positioning: ANSIStringPositioning?) -> Self {
        var style = self
        style.positioning = positioning ?? .left
        return style
    }
}
