//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/8/21.
//

import Foundation
import Swonsole

class ERGhettoView: ERConcreteView, ANSIListDelegate_ {
    var items: [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"]
    
    let list: ANSIList_ = ANSIList_()
    
    init() {
        super.init(subviews: [list])
        list.delegate = self
    }
    
    func numberOfRows(inList list: ANSIList_) -> Int {
        items.count
    }
    
    public func paint(row: Int, toWidth width: Int) -> Paintable {
        if list.activeRow == row {
            if list.receivingInput {
                // list is currently the selected column
                return StyledText(text: items[row]).onBlue.white.center
            } else {
                // just highlight the selected row
                return StyledText(text: items[row]).onDarkGray.center
            }
        } else {
            return items[row]
        }
    }
    
    override func didStartReceivingInput() {
        list.receivingInput = true
    }
    
    override func didStopReceivingInput() {
        list.receivingInput = false
    }
}

ANSIMain { renderer, start, stop in
    let view = ANSIColumnView(subviews: [
        ERGhettoView(),
        ERGhettoView(),
        ERGhettoView()
    ])

    view.verticalBorder = "|"
    view.outsideBorder = true
    view.receivingInput = true
    
    renderer.mount(ANSIPaintableHost(StyledText(text: "iMessage").center.onRed))
    renderer.mount(view)
    
    start()
}
