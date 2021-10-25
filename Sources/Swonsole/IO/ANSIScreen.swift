//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/24/21.
//

import Foundation

public class ANSIScreen {
    public static let shared = ANSIScreen()
    
    public let source: DispatchSourceSignal = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .global(qos: .userInteractive))
    
    public private(set) var width = 0
    public private(set) var height = 0
    
    private init() {
        source.setEventHandler {
            self.refresh()
            
            ANSINodeRenderer.shared.needsTrash = true
            ANSINodeRenderer.shared.render()
        }
        
        refresh()
    }
    
    private func refresh() {
        var w = winsize(), _ = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
        
        width = Int(w.ws_col)
        height = Int(w.ws_row)
    }
}
