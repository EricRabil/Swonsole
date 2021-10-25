//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/22/21.
//

import Foundation

public func ANSIMain(_ callback: (ANSIViewRenderer, _ start: () -> (), _ stop: () -> ()) -> ()) {
    let renderer = ANSIViewRenderer()
    
    callback(renderer, {
        ANSITerminal.setRawMode()
        renderer.start()
        
        dispatchMain()
    }, {
        renderer.stop()
        ANSITerminal.restoreInitialMode()
    })
}
