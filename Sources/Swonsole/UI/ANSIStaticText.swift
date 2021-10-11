//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

public class ANSIStaticText: ANSIView {
    public var text: String {
        get {
            rows.joined(separator: "\n")
        }
        set {
            rows = newValue.split(separator: "\n").map { String($0) }
        }
    }
    
    public var rows: [String] = [""]
    
    public init(_ text: String) {
        self.text = text
    }
}

public class ANSILinkedText: ANSIView {
    public var callback: () -> String
    
    public init(_ text: @autoclosure @escaping () -> String) {
        self.callback = text
    }
    
    public var text: String {
        callback()
    }
    
    public var rows: [String] {
        text.split(separator: "\n").map { String($0) }
    }
}
