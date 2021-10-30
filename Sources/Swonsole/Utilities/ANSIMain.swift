//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/24/21.
//

import Foundation

public func ANSIMain(_ callback: () -> ()) {
    ANSITerminal.shared.setRawMode()
    
    ANSIScreen.shared.source.resume()
    ANSITerminal.shared.source.resume()
    
    callback()
    
    ANSINodeRenderer.shared.loop.resume()
    
    dispatchMain()
}

public func ANSIMain(_ nodes: [ANSINode]) {
    ANSIMain {
        let root = ANSIRootNode(children: nodes)
        
        ANSINodeRenderer.shared.mount(node: root)
    }
}

public func ANSIMain(_ nodes: ANSINode...) {
    ANSIMain {
        let root = ANSIRootNode(children: nodes)
        
        ANSINodeRenderer.shared.mount(node: root)
    }
}

public func ANSIMain(@ANSINodeBuilder _ tree: () -> [ANSINode]) {
    ANSIMain(tree())
}
