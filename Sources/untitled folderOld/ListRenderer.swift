//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/8/21.
//

import Foundation
import Rainbow

private extension Collection {
    var lastIndex: Index {
        index(endIndex, offsetBy: -1)
    }
}

public class ListRenderer<Element: CustomStringConvertible> {
    public struct Options {
        public init(activeColor: NamedColor = .lightCyan, selectedPrefix: String = "*", inactivePrefix: String = "-", inactiveColor: NamedColor? = nil, multi: Bool = false, maxItems: Int? = nil) {
            self.activeColor = activeColor
            self.selectedPrefix = selectedPrefix
            self.inactivePrefix = inactivePrefix
            self.inactiveColor = inactiveColor
            self.multi = multi
            self.maxItems = maxItems
        }
        
        var activeColor: NamedColor = .lightCyan
        var selectedPrefix: String = "*"
        var inactivePrefix: String = "-"
        var inactiveColor: NamedColor? = nil
        var multi: Bool = false
        var maxItems: Int? = nil
    }
    
    public init(items: [Element], options: Options = Options()) {
        self.items = items
        self.options = options
    }
    
    public let options: Options
    public let items: [Element]
    
    public private(set) var selectedIndices: Set<Int> = []
    public var activeIndex: Int = 0 {
        didSet {
            // Automatically rolls the index over if it exceeds either start or end
            if activeIndex == items.endIndex {
                activeIndex = 0
            } else if activeIndex < 0 {
                activeIndex = items.lastIndex
            }
        }
    }
    
    /// Where to render to
    public var handle = FileHandle.standardOutput
    
    // MARK: - Pagination
    
    private var paginator = Paginator()
    
    private var visibleItems: [Int] {
        guard let maxItems = options.maxItems else {
            return Array(items.indices)
        }
        
        return paginator.paginate(indices: Array(items.indices), active: activeIndex, pageSize: maxItems)
    }
    
    // MARK: - Interaction
    
    public func toggleActiveSelection() {
        if selectedIndices.contains(activeIndex) {
            selectedIndices.remove(activeIndex)
        } else {
            if selectedIndices.count != 0 && !options.multi {
                selectedIndices = Set()
            }
            
            selectedIndices.insert(activeIndex)
        }
    }
    
    // MARK: - Text rendering
    
    /// Used to specialize first-run ANSI codes
    private var initialRender = true
    
    /// Renders a single line of text
    private func render(index: Int, active: Bool) -> String {
        let text = items[index].description
        
        var prefix: String {
            if selectedIndices.contains(index) {
                return options.selectedPrefix
            } else {
                return options.inactivePrefix
            }
        }
        
        var color: NamedColor? {
            if active {
                return options.activeColor
            } else {
                return options.inactiveColor
            }
        }
        
        if let color = color {
            return (prefix + text).applyingColor(color)
        } else {
            return prefix + text
        }
    }
    
    internal var rows: Int {
        visibleItems.count
    }
    
    public func render() {
        let visibleItems = visibleItems
        
        for (visibleIndex, index) in visibleItems.enumerated() {
            let rendered = render(index: index, active: index == activeIndex)
            let end = visibleIndex != visibleItems.lastIndex ? "\n" : ""
            write(rendered + end)
        }
    }
}

private var unhideHandles = Set<FileHandle>()
private func unhide() {
    for handle in unhideHandles {
        handle.write(ANSIEscape.cursorShow)
    }
}

private var unhideAtExit: Bool = false {
    didSet {
        if !oldValue, unhideAtExit {
            atexit(unhide)
            
            signal(SIGINT) { code in
                unhide()
                exit(code)
            }
        }
    }
}

// UX extensions
public extension ListRenderer {
    func setCursorHidden(_ hidden: Bool) {
        if hidden {
            write(ANSIEscape.cursorHide)
        } else {
            write(ANSIEscape.cursorShow)
        }
    }
    
    func attachUnhideTrap() {
        unhideHandles.insert(handle)
        unhideAtExit = true
    }
}

// MARK: - IO Helpers

private extension ListRenderer {
    func write<Text: StringProtocol>(_ text: Text) {
        handle.write(text)
    }
}

private extension FileHandle {
    func showCursor() {
        write(ANSIEscape.cursorShow)
    }
    
    func hideCursor() {
        write(ANSIEscape.cursorHide)
    }
    
    // Shuttles raw text to the file handle
    func write<Text: StringProtocol>(_ text: Text) {
        if #available(macOS 10.15.4, *) {
            try! write(contentsOf: Data(text.utf8))
        } else {
            write(Data(text.utf8))
        }
    }
}
