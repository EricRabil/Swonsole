//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/24/21.
//

import Foundation

@resultBuilder
public struct ANSINodeBuilder {
    public static func buildBlock(_ components: ANSINode...) -> [ANSINode] {
        components
    }
    
    public static func buildArray(_ components: [[ANSINode]]) -> [ANSINode] {
        components.flatMap { $0 }
    }
    
    public static func buildFinalResult(_ component: [ANSINode]) -> [ANSINode] {
        component
    }
}

public extension ANSINode {
    convenience init(@ANSINodeBuilder children: () -> [ANSINode]) {
        self.init(children: children())
    }
}
