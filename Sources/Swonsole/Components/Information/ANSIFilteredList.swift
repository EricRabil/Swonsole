//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/29/21.
//

import Foundation

public typealias ANSIFilteredListDelegate = ANSIListDelegate & ANSITextFieldDelegate

open class ANSIFilteredList: ANSINode, ANSINodeMinimumHeightConstraining {
    public let list: ANSIList
    public let textField: ANSITextField
    
    open var minimumHeight: Int {
        get { list.minimumHeight }
        set { list.minimumHeight = newValue }
    }
    
    public required init(delegate: ANSIFilteredListDelegate?) {
        list = ANSIList(delegate: delegate)
        list.managedActivation = false
        
        textField = ANSITextField()
        
        super.init()
        
        textField.delegate = delegate
        
        append(node: list)
        append(node: ANSIHorizontalBorder(character: "-"))
        append(node: textField)
    }
    
    open func replaceDelegate(newDelegate: ANSIFilteredListDelegate?) {
        list.delegate = newDelegate
        textField.delegate = newDelegate
    }
    
    open override func mounted() {
        activate()
    }
    
    open override func willUnmount() {
        deactivate()
    }
    
    open override func inputEventReceived(_ event: ANSIInputEvent) {
        list.inputEventReceived(event)
        textField.inputEventReceived(event)
    }
}

public extension ANSIFilteredList {
    func customizingTextField(_ callback: (ANSITextField) -> ANSITextField) -> Self {
        _ = callback(textField)
        return self
    }
}
