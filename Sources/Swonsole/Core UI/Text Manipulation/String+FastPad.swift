//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/29/21.
//

import Foundation

internal extension String {
    private static let spaceTable: UnsafeMutablePointer<String?> = {
        let spaceTable = UnsafeMutablePointer<String?>.allocate(capacity: 512)
        spaceTable.initialize(repeating: nil, count: 512)
        return spaceTable
    }()

    @_optimize(speed) static func spaces(repeating count: Int) -> String {
        let existing = spaceTable.advanced(by: count).pointee
        if _fastPath(existing != nil) {
            return existing!
        }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        
        for i in 0..<count {
            buffer.advanced(by: i).pointee = 32
        }
        
        spaceTable[count] = String._tryFromUTF8(UnsafeBufferPointer(start: UnsafePointer(buffer), count: count))!
        
        spaceTable.advanced(by: count).pointee = String(repeating: " ", count: count)
        return spaces(repeating: count)
    }
}
