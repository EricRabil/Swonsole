import ANSITerminal

private func SS3Letter(_ key: UInt8) -> ANSIKeyCode {
  switch key {
    case ANSIKeyCode.f1.rawValue : return .f1
    case ANSIKeyCode.f2.rawValue : return .f2
    case ANSIKeyCode.f3.rawValue : return .f3
    case ANSIKeyCode.f4.rawValue : return .f4
    default                      : return .none
  }
}

private func CSILetter(_ key: UInt8) -> ANSIKeyCode {
  switch key {
    case ANSIKeyCode.up.rawValue    : return .up
    case ANSIKeyCode.down.rawValue  : return .down
    case ANSIKeyCode.left.rawValue  : return .left
    case ANSIKeyCode.right.rawValue : return .right
    case ANSIKeyCode.home.rawValue  : return .home
    case ANSIKeyCode.end.rawValue   : return .end
    case ANSIKeyCode.f1.rawValue    : return .f1
    case ANSIKeyCode.f2.rawValue    : return .f2
    case ANSIKeyCode.f3.rawValue    : return .f3
    case ANSIKeyCode.f4.rawValue    : return .f4
    default                         : return .none
  }
}

private func CSINumber(_ key: UInt8) -> ANSIKeyCode {
  switch key {
    case 1                             : return .home
    case 4                             : return .end
    case ANSIKeyCode.insert.rawValue   : return .insert
    case ANSIKeyCode.delete.rawValue   : return .delete
    case ANSIKeyCode.pageUp.rawValue   : return .pageUp
    case ANSIKeyCode.pageDown.rawValue : return .pageDown
    case 11                            : return .f1
    case 12                            : return .f2
    case 13                            : return .f3
    case 14                            : return .f4
    case ANSIKeyCode.f5.rawValue       : return .f5
    case ANSIKeyCode.f6.rawValue       : return .f6
    case ANSIKeyCode.f7.rawValue       : return .f7
    case ANSIKeyCode.f8.rawValue       : return .f8
    case ANSIKeyCode.f9.rawValue       : return .f9
    case ANSIKeyCode.f10.rawValue      : return .f10
    case ANSIKeyCode.f11.rawValue      : return .f11
    case ANSIKeyCode.f12.rawValue      : return .f12
    default                            : return .none
  }
}

internal func isLetter(_ key: Int) -> Bool {
  return (65...90 ~= key)
}

internal func isNumber(_ key: Int) -> Bool {
  return (48...57 ~= key)
}

internal func isLetter(_ chr: Character) -> Bool {
  return ("A"..."Z" ~= chr)
}

internal func isNumber(_ chr: Character) -> Bool {
  return ("0"..."9" ~= chr)
}

internal func isLetter(_ str: String) -> Bool {
  return ("A"..."Z" ~= str)
}

internal func isNumber(_ str: String) -> Bool {
  return ("0"..."9" ~= str)
}

private func CSIMeta(_ key: UInt8) -> [ANSIMetaCode] {
  //! NOTE: if x = 1 then ~ becomes letter
  switch key {
    case  2: return [.shift]                     // ESC [ x ; 2~
    case  3: return [.alt]                       // ESC [ x ; 3~
    case  4: return [.shift, .alt]               // ESC [ x ; 4~
    case  5: return [.control]                   // ESC [ x ; 5~
    case  6: return [.shift, .control]           // ESC [ x ; 6~
    case  7: return [.alt,   .control]           // ESC [ x ; 7~
    case  8: return [.shift, .alt,   .control]   // ESC [ x ; 8~
    default: return []
  }
}

// read ANSI key code sequence
public func readKey_Patched() -> (code: ANSIKeyCode, meta: [ANSIMetaCode], chars: [Character]) {
  var code = ANSIKeyCode.none
  var meta: [ANSIMetaCode] = []

  // make sure there is data in stdin
  if !keyPressed() { return (code, meta, []) }

  var val: Int    = 0
  var key: Int    = 0
  var cmd: String = ESC
  var chars: [Character] = []
  var chr: Character

  while true {                              // read key sequence
    let char = readChar()
    chars.append(char)                      // store char in array
    cmd.append(char)                        // check for ESC combination

    if cmd == CSI {                         // found CSI command
      key = readCode()

      if isLetter(key) {                    // CSI + letter
        code = CSILetter(UInt8(key))
        break
      }
      else if isNumber(key) {               // CSI + numbers
        cmd = String(unicode(key))          // collect numbers
        repeat {
          chr = readChar()                  // char after number has been read
          if isNumber(chr) { cmd.append(chr) }
        } while isNumber(chr)
        val = Int(cmd)!                     // guaranted valid number

        if chr == ";" {                     // CSI + numbers + ;
          cmd = String(readChar())          // CSI + numbers + ; + meta
          if isNumber(cmd) { meta = CSIMeta(UInt8(cmd)!) }

          if val == 1 {                     // CSI + 1 + ; + meta
            key = readCode()                // CSI + 1 + ; + meta + letter
            if isLetter(key) { code = CSILetter(UInt8(key)) }
            break
          }
          else {                            // CSI + numbers + ; + meta + ~
            code = CSINumber(UInt8(val))
            _ = readCode()                  // dismiss the tilde (guaranted)
            break
          }
        }
        else {                              // CSI + numbers + ~ (guaranted)
          code = CSINumber(UInt8(val))
          break
        }
      }
      else { break }                        // neither letter nor numbers
    }
    else if cmd == SS3 {                    // found SS3 command
      key = readCode()
      if isLetter(key) { code = SS3Letter(UInt8(key)) }
      break
    }
    else { break }                          // unknown command is found
  }

  return (code, meta, chars)
}
