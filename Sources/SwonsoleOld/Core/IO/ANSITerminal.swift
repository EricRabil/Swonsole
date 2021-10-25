#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

public let ESC = "\u{1B}"  // Escape character (27 or 1B)
public let SS2 = ESC+"N"   // Single Shift Select of G2 charset
public let SS3 = ESC+"O"   // Single Shift Select of G3 charset
public let DCS = ESC+"P"   // Device Control String
public let CSI = ESC+"["   // Control Sequence Introducer
public let OSC = ESC+"]"   // Operating System Command

// some fancy characters, required appropriate font installed
public let RPT = "\u{e0b0}"   // right pointing triangle
public let LPT = "\u{e0b2}"   // left pointing triangle
public let RPA = "\u{e0b1}"   // right pointing angle
public let LPA = "\u{e0b3}"   // left pointing angle

public class _ANSITerminalInterface {
    public private(set) var defaultTerminal: termios = {
        var term = termios()
        
        tcgetattr(0, &term)
        
        return term
    }()
    
    private var buffer: [String]? = nil
}

public extension _ANSITerminalInterface {
    func setRawMode() {
        var raw = termios()
        tcgetattr(0, &raw)
        
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON)
        tcsetattr(0, TCSAFLUSH, &raw)
    }
    
    func restoreInitialMode() {
        tcsetattr(0, TCSAFLUSH, &defaultTerminal)
    }
}

public extension _ANSITerminalInterface {
    func request(_ command: String, endChar: Character) -> String {
      // send request
        Darwin.write(STDOUT_FILENO, command, command.count)

      // read response
      var res: String = ""
      var key: UInt8  = 0
      repeat {
        read(STDIN_FILENO, &key, 1)
        if key < 32 {
          res.append("^")  // replace non-printable ascii
        } else {
          res.append(Character(UnicodeScalar(key)))
        }
      } while key != endChar.asciiValue

      return res
    }
    
    func beginTransaction() {
        guard buffer == nil else {
            return
        }
        
        buffer = []
    }
    
    func write(_ text: String) {
        Darwin.write(STDOUT_FILENO, text, text.utf8.count)
    }
    
    func write(_ text: String..., suspend: Int = 0) {
        if let buffer = buffer {
            return self.buffer = text + buffer
        }
        
        for txt in text { Darwin.write(STDOUT_FILENO, txt, txt.utf8.count) }
        if suspend > 0 { delay(suspend) }
        if suspend < 0 { clearBuffer() }
    }
    
    func endTransaction() {
        guard let text = buffer?.joined(separator: "\0") else {
            return
        }
        
        self.buffer = nil
        Darwin.write(STDOUT_FILENO, text, text.utf8.count)
    }
}

public extension _ANSITerminalInterface {
    @inlinable func unicode(_ code: Int) -> Unicode.Scalar {
      return Unicode.Scalar(code) ?? "\0"
    }
    
    @inlinable func delay(_ ms: Int) {
      usleep(UInt32(ms * 1000))  // convert to milliseconds
    }
}

public extension _ANSITerminalInterface {
    func clearBuffer(isOut: Bool = true, isIn: Bool = true) {
      if isIn { fflush(stdin) }
      if isOut { fflush(stdout) }
    }
    
    func readChar() -> Character {
     var key: UInt8 = 0
     let res = read(STDIN_FILENO, &key, 1)
     return res < 0 ? "\0" : Character(UnicodeScalar(key))
   }
    
    func readCode() -> Int {
      var key: UInt8 = 0
      let res = read(STDIN_FILENO, &key, 1)
      return res < 0 ? 0 : Int(key)
    }
}

public let ANSITerminal = _ANSITerminalInterface()
