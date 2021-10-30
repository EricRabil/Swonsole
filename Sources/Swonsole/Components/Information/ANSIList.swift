import Foundation

public protocol ANSIListDelegate {
    var numberOfRows: Int { get }
    var maxDisplayedRows: Int { get }
    
    func render(activeRow: Int, withWidth: Int) -> String
    func render(row: Int, withWith width: Int) -> String
    func activeRow(changed newActiveRow: Int)
}

/// Nodes conforming to this will manage their own activation status when managedActivation is set to true
public protocol ANSINodeAutomaticallyActivating {
    var managedActivation: Bool { get set }
}

open class ANSIList: ANSINode, ANSINodeMinimumHeightConstraining, ANSINodeAutomaticallyActivating {
    open var managedActivation: Bool = true
    open var delegate: ANSIListDelegate? = nil
    open var minimumHeight: Int = 0
    
    open var topRow: Int = 0 { // selected view
        didSet {
            refreshRowsIfNeeded()
        }
    }
    
    open var pointer: Int = 0 {
        didSet {
            refreshRowsIfNeeded()
            delegate?.activeRow(changed: pointer)
        }
    }
    
    public init(delegate: ANSIListDelegate?) {
        self.delegate = delegate
        super.init()
    }
    
    public override init() {
        super.init()
    }
    
    open override func mounted() {
        if managedActivation {
            activate()
        }
    }
    
    open override func willUnmount() {
        if managedActivation {
            deactivate()
        }
    }
    
    private var lastRow: Int {
        max(lastNumberOfRows - 1, 0)
    }
    
    private var maxDisplayedRows: Int {
        delegate?.maxDisplayedRows ?? 0
    }
    
    // sequence of rows to be rendered
    private var rows: [Int] = []
    private var lastNumberOfRows: Int = 0
    private var rowHash: Int = 0
    
    private func latestRowHash(lastNumberOfRows: inout Int) -> Int {
        var hasher = Hasher()
        lastNumberOfRows = delegate?.numberOfRows ?? 0
        lastNumberOfRows.hash(into: &hasher)
        pointer.hash(into: &hasher)
        topRow.hash(into: &hasher)
        return hasher.finalize()
    }
    
    private func latestRows() -> [Int] {
        if lastNumberOfRows == 0 {
            return []
        }
        
        if lastNumberOfRows < maxDisplayedRows {
            return Array(0...lastRow)
        }
        
        if topRow == lastRow {
            return [lastRow] + (0..<maxDisplayedRows - 1)
        }
        
        if topRow + maxDisplayedRows > lastRow {
            return Array(topRow...lastRow) + Array(0..<(maxDisplayedRows - (lastNumberOfRows - topRow)))
        } else {
            return Array(topRow..<topRow + maxDisplayedRows)
        }
    }
    
    private func refreshRowsIfNeeded() {
        let latestRowHash = latestRowHash(lastNumberOfRows: &lastNumberOfRows)
        
        if rowHash != latestRowHash {
            rows = latestRows()
            rowHash = latestRowHash
            
            if pointer > lastNumberOfRows, lastNumberOfRows > 0 {
                pointer = lastNumberOfRows - 1
                topRow = max(pointer - mid, 0)
            }
        }
    }
    
    private var mid: Int {
        Int(floor(Double(maxDisplayedRows) / 2.0))
    }
    
    open override func inputEventReceived(_ event: ANSIInputEvent) {
        var offset: Int {
            rows.firstIndex(of: pointer) ?? 0
        }
        
        var nearTop: Bool {
            rows.contains(0)
        }
        
        var nearBottom: Bool {
            rows.contains(lastRow)
        }
        
        switch event.code {
        case .down:
            if pointer == lastRow {
                break
            }
            
            if offset == mid && !nearBottom {
                topRow += 1
                pointer += 1
            } else if nearBottom {
                pointer += 1
            } else if offset < mid {
                pointer += 1
            }
        case .up:
            if pointer == 0 {
                break
            }
            
            if offset == mid && !nearTop {
                topRow -= 1
                pointer -= 1
            } else if nearTop {
                pointer -= 1
            } else if offset > mid {
                pointer -= 1
            }
        default:
            return
        }
    }
    
    open override func render(withWidth width: Int) -> [String] {
        refreshRowsIfNeeded()
        
        var rows = rows.compactMap { row in
            row == pointer ? delegate?.render(activeRow: row, withWidth: width) : delegate?.render(row: row, withWith: width)
        }
        
        if minimumHeight > rows.count {
            rows = rows + Array(repeating: String.spaces(repeating: width), count: minimumHeight - rows.count)
        }
        
        return rows
    }
}
