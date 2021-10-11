//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/9/21.
//

import Foundation

public typealias ANSIReceiver = (ANSIPayload) -> ()

public class ANSISourceConnection {
    public var active: Bool {
        get {
            disconnect != nil
        }
        set {
            switch newValue {
            case true:
                guard disconnect == nil else {
                    return
                }
                
                disconnect = ANSISource.shared.receive(self.handler)
            case false:
                guard let disconnect = disconnect else {
                    return
                }
                
                disconnect()
                self.disconnect = nil
            }
        }
    }
    
    private let handler: (ANSIPayload) -> ()
    private var disconnect: (() -> ())?
    
    public init(_ handler: @escaping (ANSIPayload) -> ()) {
        self.handler = handler
    }
}

public class ANSISource {
    public static let shared = ANSISource()
    public static let queue = DispatchQueue.main
    
    public var count = 0
    
    typealias ReceiverRef = ANSIReceiverRef<ANSIPayload>
    
    private var underlyingSource: DispatchSourceRead!
    private var receivers: Set<ReceiverRef> = Set()
    
    // Called after normal receivers, for internal post-mutation
    internal var endReceivers: Set<ReceiverRef> = Set()
    
    private func remakeSource() {
        underlyingSource = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: ANSISource.queue)
        underlyingSource.setEventHandler {
            self.count += 1
            
            let payload = ANSITerminal.readKey()
            
            for receiver in self.receivers {
                receiver.receiver(payload)
            }
            
            for receiver in self.endReceivers {
                receiver.receiver(payload)
            }
        }
        underlyingSource.resume()
    }
    
    private init() {
    }
}

public extension ANSISource {
    func enable() {
        disable()
        remakeSource()
    }
    
    func disable() {
        underlyingSource?.cancel()
    }
}

public extension ANSISource {
    @discardableResult
    func receive(_ receiver: @escaping ANSIReceiver) -> () -> () {
        let ref = ReceiverRef(receiver: receiver)
        receivers.insert(ref)
        
        return {
            self.receivers.remove(ref)
        }
    }
    
    func removeReceivers() {
        receivers.removeAll()
        endReceivers.removeAll()
    }
}

public extension ANSISource {
    func reset() {
        removeReceivers()
    }
}
