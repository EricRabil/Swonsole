//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/17/21.
//

import Foundation

@propertyWrapper
public struct LoopedInt<EnclosingType> {
    public typealias Value = Int
    public typealias ValueKeyPath = KeyPath<EnclosingType, Value>
    public typealias SelfKeyPath = ReferenceWritableKeyPath<EnclosingType, Self>
    
    public static subscript(
            _enclosingInstance instance: EnclosingType,
            wrapped wrappedKeyPath: ValueKeyPath,
            storage storageKeyPath: SelfKeyPath
    ) -> Value {
        get {
            instance[keyPath: storageKeyPath].wrappedValue
        }
        set {
            var storage: LoopedInt {
                _read {
                    yield instance[keyPath: storageKeyPath]
                }
                _modify {
                    yield &instance[keyPath: storageKeyPath]
                }
            }
            
            let max = instance[keyPath: storage.keyPath]
            
            if newValue >= max {
                storage.wrappedValue = 0
            } else if newValue < 0 {
                storage.wrappedValue = max - 1
            } else {
                storage.wrappedValue = newValue
            }
        }
    }
    
    public var wrappedValue: Value
    
    private let keyPath: ValueKeyPath

    public init(_ keyPath: ValueKeyPath, initialValue: Value) {
        self.keyPath = keyPath
        self.wrappedValue = initialValue
    }
}
