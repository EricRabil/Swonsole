//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/29/21.
//

import Foundation

private extension String {
    func index(offset: Int) -> Index {
        index(startIndex, offsetBy: offset)
    }
}

public protocol ANSITextFieldDelegate {
    func textField(_ textField: ANSITextField, updated newText: String, oldText: String)
    func textField(_ textfield: ANSITextField, submitted finalValue: String)
}

open class ANSITextField: ANSINode {
    public struct Style {
        public init(prefixStyle: ANSIText.Style, placeholderPointerStyle: ANSIText.Style, placeholderStyle: ANSIText.Style, pointerStyle: ANSIText.Style, textStyle: ANSIText.Style, prefix: String) {
            self.prefixStyle = prefixStyle
            self.placeholderPointerStyle = placeholderPointerStyle
            self.placeholderStyle = placeholderStyle
            self.pointerStyle = pointerStyle
            self.textStyle = textStyle
            self.prefix = prefix
        }
        
        public init() {
        }
        
        public static let `default`: Style = Style()
        // effectively hides the cursor, for a disabled field
        public static let disabled: Style = (
            .default
                .withPlaceholderPointerStyle(`default`.placeholderStyle)
                .withPointerStyle(`default`.textStyle)
        )
        
        public var prefixStyle: ANSIText.Style = .default
        public var placeholderPointerStyle: ANSIText.Style = .default.backgrounded(by: .white).colored(by: .blue)
        public var placeholderStyle: ANSIText.Style = .default.colored(by: .gray)
        public var pointerStyle: ANSIText.Style = .default.backgrounded(by: .white).colored(by: .blue)
        public var textStyle: ANSIText.Style = .default
        public var prefix: String = ""
    }
    
    open var delegate: ANSITextFieldDelegate?
    
    open var style: Style = Style() {
        didSet {
            updateNodes()
        }
    }
    
    open var text: String = "" {
        didSet {
            if pointer > text.count {
                pointer = text.count
            } else {
                updateNodes() // pointer mutation calls updateNotes
            }
        }
    }
    
    open var placeholder: String = "" {
        didSet {
            if text == "" {
                updateNodes()
            }
        }
    }
    
    open var pointer: Int = 0 {
        didSet {
            pointer = min(max(pointer, 0), text.count)
            updateNodes()
        }
    }
    
    public let textGroup: ANSITextGroup = ANSITextGroup()
    
    public let prefixText: ANSIText = ANSIText()
    public let prePointerText: ANSIText = ANSIText()
    public let pointerText: ANSIText = ANSIText().backgrounded(by: .white).colored(by: .blue)
    public let postPointerText: ANSIText = ANSIText()
    
    private func updateNodes() {
        prefixText.text = style.prefix
        prefixText.style = style.prefixStyle
        
        if text == "", placeholder != "" {
            prePointerText.text = ""
            pointerText.text = String(placeholder[placeholder.startIndex])
            postPointerText.text = String(placeholder[placeholder.index(offset: 1)...])
            
            prePointerText.style = .default
            pointerText.style = style.placeholderPointerStyle
            postPointerText.style = style.placeholderStyle
            
            return
        }
        
        prePointerText.style = style.textStyle
        pointerText.style = style.pointerStyle
        postPointerText.style = style.textStyle
        
        if pointer == text.count {
            prePointerText.text = text
            pointerText.text = " "
            postPointerText.text = ""
        } else if pointer == 0 {
            prePointerText.text = ""
            pointerText.text = String(text[placeholder.startIndex])
            postPointerText.text = String(text[text.index(offset: 1)...])
        } else {
            prePointerText.text = String(text[text.startIndex..<text.index(offset: pointer)])
            pointerText.text = String(text[text.index(offset: pointer)])
            postPointerText.text = String(text[text.index(offset: pointer + 1)...])
        }
    }
    
    public init(text: String = "") {
        self.text = text
        
        textGroup.append(node: prefixText)
        textGroup.append(node: prePointerText)
        textGroup.append(node: pointerText)
        textGroup.append(node: postPointerText)
        
        super.init()
        
        append(node: textGroup)
    }
    
    open override func inputEventReceived(_ event: ANSIInputEvent) {
        switch event.code {
        case .left:
            if pointer > 0 {
                pointer -= 1
            }
        case .right:
            if pointer < text.count {
                pointer += 1
            }
        case .none:
            for char in event.characters {
                switch char {
                case "\u{1B}":
                    break
                case "\t":
                    break
                case "\r":
                    fallthrough
                case "\n":
                    delegate?.textField(self, submitted: text)
                case "\u{7F}": // backspace
                    if pointer == 0 {
                        return
                    } else {
                        let newPointer = pointer == text.count ? nil : pointer - 1, oldText = text
                        text.remove(at: text.index(offset: pointer - 1))
                        
                        if let newPointer = newPointer {
                            pointer = newPointer
                        }
                        
                        delegate?.textField(self, updated: text, oldText: oldText)
                    }
                case "\u{04}": // delete
                    if pointer == text.count {
                        return
                    } else {
                        let oldText = text
                        text.remove(at: text.index(text.startIndex, offsetBy: pointer))
                        
                        delegate?.textField(self, updated: text, oldText: oldText)
                    }
                default:
                    let oldText = text
                    text.insert(char, at: text.index(text.startIndex, offsetBy: pointer))
                    pointer += 1
                    
                    delegate?.textField(self, updated: text, oldText: oldText)
                }
            }
        default:
            break
        }
    }
}

public extension ANSITextField.Style {
    private func cloning(_ callback: (inout Self) -> ()) -> Self {
        var value = self
        callback(&value)
        return value
    }
    
    func withTextStyle(_ textStyle: ANSIText.Style?) -> Self {
        cloning {
            $0.textStyle = textStyle ?? Self.default.textStyle
        }
    }
    
    func withPointerStyle(_ style: ANSIText.Style?) -> Self {
        cloning {
            $0.pointerStyle = style ?? Self.default.pointerStyle
        }
    }
    
    func withPlaceholderStyle(_ style: ANSIText.Style? = nil) -> Self {
        cloning {
            $0.placeholderStyle = style ?? Self.default.placeholderStyle
        }
    }
    
    func withPlaceholderPointerStyle(_ style: ANSIText.Style?) -> Self {
        cloning {
            $0.placeholderPointerStyle = style ?? Self.default.placeholderPointerStyle
        }
    }
    
    func withPrefix(_ prefix: String? = nil) -> Self {
        cloning {
            $0.prefix = prefix ?? Self.default.prefix
        }
    }
    
    func withPrefixStyle(_ style: ANSIText.Style?) -> Self {
        cloning {
            $0.prefixStyle = style ?? Self.default.prefixStyle
        }
    }
}

public extension ANSITextField {
    func withPlaceholder(_ text: String?) -> Self {
        placeholder = text ?? ""
        return self
    }
    
    func withStyle(_ style: Style) -> Self {
        self.style = style
        return self
    }
}
