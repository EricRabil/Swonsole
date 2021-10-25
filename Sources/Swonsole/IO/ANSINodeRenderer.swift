//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/24/21.
//

import Foundation

private extension Array where Element: AnyObject {
    mutating func removeAll(equatingTo element: Element) {
        removeAll(where: {
            $0 === element
        })
    }
    
    func contains(object: Element) -> Bool {
        contains(where: { $0 === object })
    }
}

// Nodes are rendered in the order they are inserted
public class ANSINodeRenderer {
    public static let shared = ANSINodeRenderer()
    private init() {
        loop = DispatchSource.makeTimerSource(flags: .strict, queue: .global(qos: .userInteractive))
        loop.setEventHandler(handler: render)
        loop.schedule(deadline: .now(), repeating: .milliseconds(16), leeway: .never)
    }
    
    public let loop: DispatchSourceTimer
    
    public private(set) var nodes: [ANSIRootNode] = [] // mounted nodes
    public private(set) var pointer = ANSICursor.shared.coordinates.y // row of the top of the render
    
    // signal that the next render should re-print every row regardless of whether they changed
    // useful to fix the terminal in-place after a resize
    public var needsTrash = false
    
    // record of previous render
    private var previousRows: [String] = []
}

// MARK: - Rendering

public extension ANSINodeRenderer {
    // shifts lastTop down the number of rows of the last render
    // missing rows will be created next render
    func shift(by offset: Int? = nil) {
        pointer = pointer(offsetBy: offset ?? previousRows.count)
        needsTrash = true
    }
    
    // render all mounted nodes to the terminal
    @_optimize(speed) func render() {
        let width = ANSIScreen.shared.width
        
        let lines = nodes.flatMap { $0.render(withWidth: width) }
        
        nudgePointer(count: lines.count)
        
        var moved = false
        
        for (index, line) in lines.enumerated() {
            if !needsTrash, previousRows.count > index && previousRows[index] == line {
                continue
            }
            
            ANSICursor.shared.moveTo(pointer(offsetBy: index), 0)
            ANSITerminal.shared.clearLine()
            ANSITerminal.shared.write(line)
            moved = true
        }
        
        if moved {
            ANSICursor.shared.moveTo(pointer(offsetBy: lines.count), 0)
        }
        
        needsTrash = false
        
        previousRows = lines
    }
}

// MARK: - Mount/unmount

public extension ANSINodeRenderer {
    func mount(node: ANSIRootNode, position: Int? = nil) {
        guard !nodes.contains(object: node) else {
            return
        }
        
        if let position = position, nodes.indices.contains(position) {
            nodes.insert(node, at: position)
        } else {
            nodes.append(node)
        }
        
        node.enteredRenderer()
        node.emitMounted()
    }
    
    func unmount(node: ANSIRootNode) {
        guard nodes.contains(object: node) else {
            return
        }
        
        node.emitWillUnmount()
        nodes.removeAll(equatingTo: node)
        node.leftRenderer()
    }
}

internal extension ANSINodeRenderer {
    // Sets the pointer to the current ANSI cursor row
    // Please don't call this unless you're trying to rebuild state
    func resetPointer() {
        pointer = ANSICursor.shared.coordinates.y
    }
}

fileprivate extension ANSINodeRenderer {
    @_transparent func pointer(offsetBy offset: Int) -> Int {
        min(pointer + offset, ANSIScreen.shared.height)
    }
    
    @_transparent var rowsBelowPointer: Int { // free space below current pointer
        max(ANSIScreen.shared.height - pointer, 0)
    }
    
    // ensures there is enough space in the terminal if there arent enough lines
    // prints additional lines if we are at the bottom and out of room
    @_optimize(speed) func nudgePointer(count neededRows: Int) {
        if rowsBelowPointer >= neededRows {
            return // we have enough rows
        }
        
        let missingRows = neededRows - rowsBelowPointer
        
        for _ in (0..<missingRows) {
            ANSITerminal.shared.write("\n")
        }
        
        pointer = ANSIScreen.shared.height - neededRows // set pointer to n rows from bottom
        needsTrash = true
    }
}
