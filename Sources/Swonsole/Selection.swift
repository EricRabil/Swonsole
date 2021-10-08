//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/8/21.
//

import Foundation
import ANSITerminal

private func readKeyBlocking() -> (code: ANSIKeyCode, meta: [ANSIMetaCode], [Character]) {
    while !keyPressed() {}
    
    return readKey_Patched()
}

public func getSelection<Element: CustomStringConvertible>(_ items: [Element], options: ListRenderer<Element>.Options = .init()) -> [Element] {
    let renderer = ListRenderer(items: items, options: options)

    renderer.setCursorHidden(true)
    renderer.attachUnhideTrap()

    while true {
        renderer.render()
        
        let (code, _, chars) = readKeyBlocking()
        
        switch code {
        case .up:
            renderer.activeIndex -= 1
        case .down:
            renderer.activeIndex += 1
        default:
            guard chars.count == 1, let char = chars.first else {
                continue
            }
            
            switch char {
            case " ":
                renderer.toggleActiveSelection()
            case "\r":
                return renderer.selectedIndices.map { items[$0] }
            default:
                continue
            }
        }
    }
}
