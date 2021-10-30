//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/23/21.
//

import Foundation
import Swonsole

extension ANSIText {
    private static var recycler: [ObjectIdentifier: [Int: ANSIText]] = [:]
    
    @_transparent @_optimize(speed) static func recycledNode<Object: AnyObject>(forNode node: Object, index: Int) -> ANSIText {
        let key = ObjectIdentifier(node)
        
        var text = recycler[key]?[index]
        
        if _fastPath(text != nil) {
            return text!
        }
        
        text = ANSIText()
        
        recycler[key, default: [:]][index] = text!
        
        return text!
    }
}

class ListProvider: ANSIListDelegate {
    var rows: [String]
    
    init(rows: [String]) {
        self.rows = rows
    }
    
    var maxDisplayedRows: Int {
        10
    }
    
    var numberOfRows: Int {
        rows.count
    }
    
    func render(activeRow row: Int, withWidth width: Int) -> String {
        ANSIText.recycledNode(forNode: self, index: row)
            .withText(" * \(rows[row])")
            .render(withWidth: width).first ?? ""
    }
    
    func render(row: Int, withWith width: Int) -> String {
        ANSIText.recycledNode(forNode: self, index: row)
            .withText("   \(rows[row])")
            .render(withWidth: width).first ?? ""
    }
}

var listProvider = ListProvider(rows: [
    "hey", "there", "how", "are", "you", "hey", "there", "how", "are", "you", "hey", "there", "how", "are", "you", "hey", "there", "how", "are", "you"
])

struct GridProvider: ANSINavigableGridDelegate {
    var trackingNodes: [ANSIText] = [
        ANSIText(text: "HEYYYYY"),
        ANSIText(text: "its meeeee"),
        ANSIText(text: "lol")
    ]
    
    func column(activated index: Int, replacing oldIndex: Int?) {
        trackingNodes[index].color = .black
        trackingNodes[index].backgroundColor = .white
        
        if let oldIndex = oldIndex {
            trackingNodes[oldIndex].color = .default
            trackingNodes[oldIndex].backgroundColor = .default
        }
    }
}

var gridProvider = GridProvider()

ANSIMain(
    ANSIText(text: "iMessage Cloud").backgrounded(by: .gray).colored(by: .black).positioned(by: .center),
    ANSIList(delegate: listProvider),
    ANSINavigableGrid(children: gridProvider.trackingNodes).withRules(.flex, .flex, .flex)
        .delegating(to: gridProvider)
        .withMinimumHeight(10)
)
