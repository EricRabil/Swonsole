//
//  ANSIRootNode.swift
//  
//
//  Created by Eric Rabil on 10/23/21.
//

import Foundation

public func ANSIRenderNode(_ node: ANSINode, withWidth width: Int) -> [String] {
    if node.hidden {
        return []
    }
    
    var rows = node.render(withWidth: width)
    
    if node is ANSINodeCustomCompositing {
        return rows
    }
    
    node.walkChildren { node -> Bool in
        if node.hidden {
            return false
        }
        
        rows += node.render(withWidth: width)
        
        return !(node is ANSINodeCustomCompositing)
    }
    
    return rows
}

public class ANSIRootNode: ANSINode {
    public override func render(withWidth width: Int) -> [String] {
        var rows = [String]()
        
        walkChildren { node -> Bool in
            if node.hidden {
                return false
            }
            
            rows += node.render(withWidth: width)
            
            return !(node is ANSINodeCustomCompositing)
        }
        
        return rows
    }
}
