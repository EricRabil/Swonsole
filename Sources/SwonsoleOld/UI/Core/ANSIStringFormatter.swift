//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

internal class ANSIStringFormatter {
    let field: ANSITextField
    
    init(field: ANSITextField) {
        self.field = field
    }
    
    var value: String {
        field.value
    }
    
    var placeholder: String {
        field.placeholder ?? ""
    }
    
    var prefix: String {
        field.prefix ?? ""
    }
    
    var suffix: String {
        field.suffix ?? ""
    }
    
    var isEmpty: Bool {
        value.count == 0
    }
    
    var formattedText: String {
        if isEmpty {
            return [prefix, placeholder, suffix].joined()
        }
        
        return [prefix, value, suffix].joined()
    }
    
    var basePosition: Int {
        prefix.count + 1
    }
    
    var cursorPosition: Int {
        if isEmpty {
            return basePosition
        }
        
        return basePosition + field.position
    }
}
