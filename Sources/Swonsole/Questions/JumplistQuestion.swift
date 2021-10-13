//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/11/21.
//

import Foundation

public final class JumplistQuestion: Question, ListBasedQuestion, ANSIView, ANSIListDelegate {
    public let options: [(Character, String)]
    
    private var chars: [Character] {
        options.map(\.0)
    }
    
    private var strings: [String] {
        options.map(\.1)
    }
    
    private var binding: [Character: String] {
        options.reduce(into: [Character: String]()) { dict, pair in dict[pair.0] = pair.1 }
    }
    
    public let label: ANSITextField
    public let list: ANSIList = ANSIList()
    
    public lazy var subviews: [ANSIView] = [label, list]
    
    public var callback: ((Character) -> ())?
    private var completion: (() -> ())?
    private lazy var source = ANSISourceConnection { payload in
        guard payload.chars.count == 1 else {
            return
        }
        
        guard self.chars.contains(payload.chars[0]) else {
            return
        }
        
        self.registerSinglePreRenderLink {
            self.list.activeIndex = self.chars.firstIndex(of: payload.chars[0])!
            self.registerSinglePostRenderLink {
                self.end(withCharacter: payload.chars[0])
            }
        }
    }
    
    public init(prompt: String, input: [(Character, String)], _ callback: ((Character) -> ())? = nil) {
        self.label = ANSITextField(initialValue: QUESTIONMARK + prompt)
        self.callback = callback
        self.options = input
        
        list.pageSize = min(input.count, 10)
        list.allowsSelection = false
        list.delegate = self
    }
    
    public func numberOfRows(forList list: ANSIList) -> Int {
        options.count
    }
    
    public func text(forRow row: Int, inList list: ANSIList) -> String {
        let raw = "\(chars[row])) \(strings[row])"
        
        if row == list.activeIndex {
            return ("›" + raw).lightBlue
        } else {
            return " " + raw
        }
    }
    
    public func activate(_ completion: @escaping () -> ()) {
        self.completion = completion
        list.active = true
        source.active = true
    }
    
    private func end(withCharacter character: Character) {
        list.active = false
        source.active = false
        completion?()
        callback?(character)
    }
    
    public func submit(_ list: ANSIList) {
        end(withCharacter: chars[list.activeIndex])
    }
}
