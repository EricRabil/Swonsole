//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

public class ANSIFilteredList: ANSIView, ANSIListDelegate, ANSITextFieldDelegate {
    public var list: ANSIList
    public var textField: ANSITextField
    public var active: Bool {
        get { sourceConnection.active }
        set {
            if !newValue {
                sourceConnection.active = false
                textField.active = false
                list.active = false
            } else {
                sourceConnection.active = true
                list.active = true
                textField.active = false
            }
        }
    }
    
    public var subviews: [ANSIView] {
        [list, textField]
    }
    
    public var delegate: ANSIListDelegate? {
        didSet { refresh() }
    }
    
    private lazy var sourceConnection = ANSISourceConnection { payload in
        if payload.chars.count == 1 {
            switch payload.chars.first {
            case "i":
                if !self.textField.active {
                    self.textField.active = true
                    self.list.active = false
                }
            case "\r":
                fallthrough
            case "\n":
                if self.textField.active {
                    self.textField.active = false
                    self.list.active = true
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
        self.list = ANSIList()
        self.textField = ANSITextField(initialValue: filterText)
        
        self.list.delegate = self
        self.textField.delegate = self
    }
    
    public func textField(_ field: ANSITextField, valueChanged value: String) {
        refresh(withFilter: value)
    }
    
    public func willRender() {
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
