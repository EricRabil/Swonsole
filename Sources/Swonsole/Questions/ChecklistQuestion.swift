//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/11/21.
//

import Foundation

public final class ChecklistQuestion: Question, ListBasedQuestion, ANSIView, ANSIListDelegate {
    public typealias Input = [String]
    
    public typealias Output = [Int]
    
    public let options: [String]
    
    public let label: ANSITextField
    public let list: ANSIList
    public var checked = Set<Int>()
    public var callback: (([Int]) -> ())?
    private var completion: (() -> ())?
    
    public lazy var subviews: [ANSIView] = [label, list]
    
    public init(prompt: String, input options: [String], _ callback: (([Int]) -> ())? = nil) {
        self.label = ANSITextField(initialValue: QUESTIONMARK + prompt)
        self.list = ANSIList()
        self.callback = callback
        self.options = options
        
        list.pageSize = min(options.count, 6)
        list.allowsSelection = true
        
        self.list.delegate = self
    }
    
    public func activate(_ completion: @escaping () -> ()) {
        self.completion = completion
        list.active = true
    }
    
    public func numberOfRows(forList list: ANSIList) -> Int {
        options.count
    }
    
    public func text(forRow row: Int, inList list: ANSIList) -> String {
        let prefix = checked.contains(row) ? "◉ ".lightGreen : "◯ "
        let raw = options[row]
        
        if row == list.activeIndex {
            return prefix + raw.lightBlue
        } else {
            return prefix + raw
        }
    }
    
    public func list(_ list: ANSIList, selectedRow row: Int) {
        if checked.contains(row) {
            checked.remove(row)
        } else {
            checked.insert(row)
        }
    }
    
    public func submit(_ list: ANSIList) {
        completion?()
        callback?(Array(checked))
    }
}
