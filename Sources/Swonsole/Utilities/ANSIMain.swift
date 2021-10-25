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
