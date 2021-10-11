//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/11/21.
//

import Foundation

public func DebuggingView() -> ANSIView {
    ANSIGroup(
        ANSILinkedText("Last top: " + ANSIRenderer.shared.lastTop.description),
        ANSILinkedText("Events processed: " + ANSISource.shared.count.description)
    )
}

public protocol ListBasedQuestion {
    var list: ANSIList { get }
}

public extension ListBasedQuestion {
    @discardableResult
    func withActiveIndex(_ index: Int) -> Self {
        list.activeIndex = index
        return self
    }
}

public final class ListQuestion: Question, ListBasedQuestion, ANSIView, ANSIListDelegate {
    public let options: [String]
    
    public let label: ANSITextField
    public let list: ANSIList
    
    public var callback: ((Int) -> ())?
    private var completion: (() -> ())?
    
    public lazy var subviews: [ANSIView] = [label, list]
    
    public init(prompt: String, input options: [String], _ callback: ((Int) -> ())? = nil) {
        self.label = ANSITextField(initialValue: QUESTIONMARK + prompt)
        self.list = ANSIList()
        self.callback = callback
        self.options = options
        
        list.pageSize = min(options.count, 6)
        list.allowsSelection = false
        
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
        if row == list.activeIndex {
            return ("› " + options[row]).lightBlue
        } else {
            return ("  " + options[row])
        }
    }
    
    public func submit(_ list: ANSIList) {
        completion?()
        callback?(list.activeIndex)
    }
}
