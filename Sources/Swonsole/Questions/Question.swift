//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/11/21.
//

import Foundation

extension _ANSIScreenInterface {
    var nearBottom: Bool {
        let (currentRow,_) = readCursorPos(), (rows,_) = readScreenSize()
        
        return currentRow == rows || (rows - 1) == currentRow
    }
}

public extension ANSIViewRenderer {
    static var defaultRenderer: ANSIViewRenderer {
        sharedRenderer
    }
    
    // Call at exit
    func shutdown() {
        ANSITerminal.setRawMode()
        
        if ANSIScreen.nearBottom {
            print()
        }
        
        ANSIScreen.cursorOn()
        ANSITerminal.restoreInitialMode()
        ANSISource.shared.disable()
    }
}

internal let QUESTIONMARK = "? ".lightGreen

public protocol QuestionDispatch: ANSIView {
    func activate(_ completion: @escaping () -> ())
}

public protocol Question: QuestionDispatch {
    associatedtype Input
    associatedtype Output
    
    var callback: ((Output) -> ())? { get set }
    
    init(prompt: String, input: Input, _ callback: ((Output) -> ())?)
    @discardableResult
    static func ask(prompt: String, input: Input, _ callback: @escaping (Output) -> ()) -> Self /// one-shot question
}

private let sharedRenderer = ANSIViewRenderer()

public extension Question {
    @discardableResult
    static func ask(prompt: String, input: Input, _ callback: @escaping (Output) -> ()) -> Self {
        let question = Self.init(prompt: prompt, input: input, callback)
        
        ANSITerminal.setRawMode()
        ANSIScreen.cursorOff()
        
        sharedRenderer.start()
        sharedRenderer.mount(question)
        
        question.activate {
            sharedRenderer.flush()
        }
        
        return question
    }
    
    func activate(_ completion: @escaping () -> ()) {}
}

/// Asks a series of questions
public class Interviewer: ANSIView {
    private var questions: [QuestionDispatch]
    private let renderer = ANSIViewRenderer()
    private let callback: () -> ()
    private var firstRun = true
    
    public init(_ questions: QuestionDispatch..., callback: @escaping () -> ()) {
        self.questions = questions.reversed()
        self.callback = callback
    }
    
    func next() {
        if firstRun {
            firstRun = false
        } else {
            
        }
        
        guard let question = questions.popLast() else {
            return callback()
        }
        
        renderer.mount(ANSISplitView(question, DebuggingView()))
        renderer.start()
        
        question.activate(self.next)
    }
    
    public func start() {
        next()
    }
}
