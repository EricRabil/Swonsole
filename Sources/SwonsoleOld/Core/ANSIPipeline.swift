//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

public class ANSIReceiverRef<Payload>: Hashable {
    public static func == (lhs: ANSIReceiverRef, rhs: ANSIReceiverRef) -> Bool {
        lhs === rhs
    }
    
    public typealias Receiver = (Payload) -> ()
    
    public let receiver: Receiver
    
    public init(receiver: @escaping Receiver) {
        self.receiver = receiver
    }
    
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}
