//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

public class ANSIFilteredList: ERConcreteView, ANSIListDelegate, ANSITextFieldDelegate {
    public var list: ANSIList
    public var textField: ANSITextField
    public override var receivingInput: Bool {
        get { super.receivingInput }
        set {
            super.receivingInput = newValue
            
            if !newValue {
                textField.active = false
                list.receivingInput = false
            } else {
                list.receivingInput = true
                textField.active = false
            }
        }
    }
    
    public var delegate: ANSIListDelegate? {
        didSet { refresh() }
    }
    
    public override func inputReceived(_ payload: ANSIPayload) {
        if payload.chars.count == 1 {
            switch payload.chars.first {
            case "i":
                if !textField.active {
                    textField.active = true
                    list.receivingInput = false
                }
            case "\r":
                fallthrough
            case "\n":
                if textField.active {
                    textField.active = false
                    list.receivingInput = true
                }
            default:
                break
            }
        }
    }
    
    private func items() -> [String] {
        guard let delegate = delegate else {
            return []
        }
        
        return (0..<delegate.numberOfRows(forList: list)).map { delegate.text(forRow: $0, inList: list) }
    }
    
    private var filteredItems: [String] = []
    private var filteredItemIndexMap: [Int: Int] = [:]
    
    private func refresh(withFilter filter: String? = nil) {
        let filterText = filter ?? textField.value
        
        if filterText.count == 0 {
            filteredItems = items()
            filteredItemIndexMap = filteredItems.indices.reduce(into: [Int:Int]()) { dict, index in dict[index] = index }
            return
        }
        
        let (filteredItems, filteredItemIndexMap) = items().enumerated().filter { _, text in
            text.contains(filterText)
        }.enumerated().reduce(into: ([String](), [Int: Int]())) { storage, data in
            storage.0.append(data.element.element)
            storage.1[data.offset] = data.element.offset
        }
        
        self.filteredItems = filteredItems
        self.filteredItemIndexMap = filteredItemIndexMap
    }
    
    private var removeReceiver: (() -> ())?
    
    public init(filterText: String = "") {
        list = ANSIList()
        textField = ANSITextField(initialValue: filterText)
        
        super.init(subviews: [list, textField])
        
        list.delegate = self
        textField.delegate = self
    }
    
    public func textField(_ field: ANSITextField, valueChanged value: String) {
        refresh(withFilter: value)
    }
    
    public override func willRender() {
        refresh()
    }
    
    public func text(forRow row: Int, inList list: ANSIList) -> String {
        filteredItems[row]
    }
    
    public func numberOfRows(forList list: ANSIList) -> Int {
        filteredItems.count
    }
    
    public func list(_ list: ANSIList, selectedRow row: Int) {
        guard let mappedIndex = filteredItemIndexMap[row] else {
            return
        }
        
        delegate?.list(list, selectedRow: mappedIndex)
    }
    
    public func submit(_ list: ANSIList) {
        delegate?.submit(list)
    }
}
