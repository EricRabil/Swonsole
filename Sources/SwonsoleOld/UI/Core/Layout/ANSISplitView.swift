//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/10/21.
//

import Foundation

public protocol ANSISplitViewDelegate: ANSIViewDelegate {
    // override the default width calculation of availableCols / subviews.count
    func width(forColumn column: Int, inView splitView: ANSISplitView) -> Int
}

public extension ANSISplitViewDelegate {
    func width(forColumn column: Int, inView splitView: ANSISplitView) -> Int {
        splitView.renderWidth / splitView.subviews.count
    }
}

public extension ANSIView {
    func walk(_ cb: (ANSIView) -> ()) {
        cb(self)
        
        for view in subviews {
            view.walk(cb)
        }
    }
}

open class ANSISplitView: ERConcreteMutableView, ANSIViewDelegating, ANSIViewCustomCompositing, _ANSIColumnCompositorDelegate {
    private lazy var table = _ANSIColumnCompositor(delegate: self)
    
    public var verticalBorder: String? {
        get { table.verticalBorder }
        set { table.verticalBorder = newValue }
    }
    
    public var outsideBorder: Bool {
        get { table.outsideBorder }
        set { table.outsideBorder = newValue }
    }
    
    open var delegate: ANSISplitViewDelegate?
    
    open override func willRender(withWidth width: Int) {
        super.willRender(withWidth: width)
        
        guard subviews.count > 0 else {
            return rows = [String]()
        }
        
        table = table.flush(newSize: subviews.count)
        
        for (column, subview) in subviews.enumerated() {
            table.eat(view: subview, column: column)
        }
        
        rows = table.rows(withWidth: width)
    }
    
    open override func rendered(toRows rows: [Int]) {
        guard let offset = rows.first else {
            return
        }
        
        for subview in subviews {
            subview.walk { view in
                if let (start, end) = table.rows[ObjectIdentifier(view)] {
                    view.rendered(toRows: (start + offset)...(end + offset))
                }
            }
        }
    }
    
    // MARK: - Implementation details
    
    func width(forColumn column: Int) -> Int { // width of a column
        delegate?.width(forColumn: column, inView: self) ?? (renderWidth / subviews.count)
    }
    
    func numberOfColumns() -> Int {
        subviews.count
    }
}
