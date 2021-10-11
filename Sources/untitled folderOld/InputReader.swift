import Foundation

// libdispatch-backed input poller
public class InputReader {
    public static var previousTerm = [FileHandle: termios]()
    
    private static func initStruct<S>() -> S {
        let struct_pointer = UnsafeMutablePointer<S>.allocate(capacity: 1)
        let struct_memory = struct_pointer.pointee
        struct_pointer.deallocate()
        return struct_memory
    }
    
    public static func enableRawMode(fileHandle: FileHandle) {
        var raw: termios = initStruct()
        tcgetattr(fileHandle.fileDescriptor, &raw)

        if let _ = previousTerm[fileHandle] {
            return
        }
        
        let original = raw

        raw.c_lflag &= ~(UInt(ECHO | ICANON))
        tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &raw);

        previousTerm[fileHandle] = original
    }
    
    public static func restoreRawMode(fileHandle: FileHandle) {
        guard var term = previousTerm.removeValue(forKey: fileHandle) else {
            return
        }
        
        tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &term)
    }
    
    public let fileDescriptor: Int32
    public let queue: DispatchQueue
    
    public typealias EventHandler = ((code: ANSIKeyCode, meta: [ANSIMetaCode], chars: [Character])) -> ()
    
    private let source: DispatchSourceRead
    private var eventHandler: EventHandler?
    
    public init(fileDescriptor: Int32, queue: DispatchQueue = .main) {
        self.fileDescriptor = fileDescriptor
        self.queue = queue
        self.source = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor, queue: queue)
        
        source.setEventHandler {
            self.eventHandler?(readKey())
        }
    }
    
    public func setEventHandler(handler: @escaping EventHandler) {
        self.eventHandler = handler
    }
    
    public func resume() {
        source.resume()
    }
    
    public func cancel() {
        source.cancel()
    }
}
