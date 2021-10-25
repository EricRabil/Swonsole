//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/23/21.
//

import Foundation
import Swonsole

ANSIMain {
    let root = ANSIRootNode()
    let group = ANSIRowGroup()
    
    group.rules = [
        .flex, .ratio(5.0 / 6.0), .flex
    ]
    
    group.append(node: ANSIText(text: "red").backgrounded(by: .red))
    group.append(node: ANSIText(text: "green").backgrounded(by: .green).positioned(by: .center))
    group.append(node: ANSIText(text: "blue").backgrounded(by: .blue))
    
    root.append(node: group)
    
    ANSINodeRenderer.shared.mount(node: root)
}
