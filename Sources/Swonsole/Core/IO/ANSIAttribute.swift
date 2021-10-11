public enum ANSIAttr: UInt8, CaseIterable {
  /* text styling */
  case normal         = 0
  case bold           = 1
  case dim            = 2
  case italic         = 3
  case underline      = 4
  case blink          = 5
  case overline       = 6
  case inverse        = 7
  case hidden         = 8
  case strike         = 9
  case noBold         = 21
  case noDim          = 22
  case noItalic       = 23
  case noUnderline    = 24
  case noBlink        = 25
  case noOverline     = 26
  case noInverse      = 27
  case noHidden       = 28
  case noStrike       = 29
  /* foreground text coloring */
  case black          = 30
  case red            = 31
  case green          = 32
  case brown          = 33
  case blue           = 34
  case magenta        = 35
  case cyan           = 36
  case gray           = 37
  case fore256Color   = 38
  case `default`      = 39
  case darkGray       = 90
  case lightRed       = 91
  case lightGreen     = 92
  case yellow         = 93
  case lightBlue      = 94
  case lightMagenta   = 95
  case lightCyan      = 96
  case white          = 97
  /* background text coloring */
  case onBlack        = 40
  case onRed          = 41
  case onGreen        = 42
  case onBrown        = 43
  case onBlue         = 44
  case onMagenta      = 45
  case onCyan         = 46
  case onGray         = 47
  case back256Color   = 48
  case onDefault      = 49
  case onDarkGray     = 100
  case onLightRed     = 101
  case onLightGreen   = 102
  case onYellow       = 103
  case onLightBlue    = 104
  case onLightMagenta = 105
  case onLightCyan    = 106
  case onWhite        = 107
    
    static let allEscapes: [String] = allCases.map(\.str)
    
    var str: String {
        CSI+"\(rawValue)m"
    }
}

extension String {
    func appending(_ char: Character) -> String {
        var copy = self
        copy.append(char)
        return self
    }
}

extension String {
    static func + (lhs: String, rhs: Character) -> String {
        var copy = lhs
        copy.append(rhs)
        return copy
    }
}

extension ANSIAttr {
    func wrap(_ char: Character) -> String {
        return CSI + "\(rawValue)m" + char
    }
}

internal private(set) var isOpenedColor = false
internal private(set) var isOpenedStyle = false

public extension String {
  private func style(_ aStyle: ANSIAttr) -> String {
    guard !self.isEmpty else { return self }

    if aStyle == .normal {
      return CSI+"\(aStyle.rawValue)m" + self
    } else {
      if isOpenedStyle {
        return CSI+"\(aStyle.rawValue)m" + self
      }
      else {
        return CSI+"\(aStyle.rawValue)m" + self + CSI+"\(ANSIAttr.normal.rawValue)m"
      }
    }
  }

  /* ––––– text styling ––––– */
  var normal:    String { return style(.normal) }
  var bold:      String { return style(.bold) }
  var dim:       String { return style(.dim) }
  var italic:    String { return style(.italic) }
  var underline: String { return style(.underline) }
  var blink:     String { return style(.blink) }
  var overline:  String { return style(.overline) }
  var inverse:   String { return style(.inverse) }
  var hidden:    String { return style(.hidden) }
  var strike:    String { return style(.strike) }

  private func color(_ aColor: ANSIAttr) -> String {
    guard !self.isEmpty else { return self }

    if isOpenedColor {
      return CSI+"\(aColor.rawValue)m" + self
    }
    else {
      return CSI+"\(aColor.rawValue)m" + self +
             CSI+"\(ANSIAttr.`default`.rawValue);\(ANSIAttr.onDefault.rawValue)m"
    }
  }

  /* ––––– text coloring (16) ––––– */
  var black         : String { return color(.black) }
  var red           : String { return color(.red) }
  var green         : String { return color(.green) }
  var brown         : String { return color(.brown) }
  var blue          : String { return color(.blue) }
  var magenta       : String { return color(.magenta) }
  var cyan          : String { return color(.cyan) }
  var gray          : String { return color(.gray) }
  var `default`     : String { return color(.`default`) }
  var darkGray      : String { return color(.darkGray) }
  var lightRed      : String { return color(.lightRed) }
  var lightGreen    : String { return color(.lightGreen) }
  var yellow        : String { return color(.yellow) }
  var lightBlue     : String { return color(.lightBlue) }
  var lightMagenta  : String { return color(.lightMagenta) }
  var lightCyan     : String { return color(.lightCyan) }
  var white         : String { return color(.white) }
  var onBlack       : String { return color(.onBlack) }
  var onRed         : String { return color(.onRed) }
  var onGreen       : String { return color(.onGreen) }
  var onBrown       : String { return color(.onBrown) }
  var onBlue        : String { return color(.onBlue) }
  var onMagenta     : String { return color(.onMagenta) }
  var onCyan        : String { return color(.onCyan) }
  var onGray        : String { return color(.onGray) }
  var onDefault     : String { return color(.onDefault) }
  var onDarkGray    : String { return color(.onDarkGray) }
  var onLightRed    : String { return color(.onLightRed) }
  var onLightGreen  : String { return color(.onLightGreen) }
  var onYellow      : String { return color(.onYellow) }
  var onLightBlue   : String { return color(.onLightBlue) }
  var onLightMagenta: String { return color(.onLightMagenta) }
  var onLightCyan   : String { return color(.onLightCyan) }
  var onWhite       : String { return color(.onWhite) }
  // for more expressive foreground color naming
  var asBlack       : String { return color(.black) }
  var asRed         : String { return color(.red) }
  var asGreen       : String { return color(.green) }
  var asBrown       : String { return color(.brown) }
  var asBlue        : String { return color(.blue) }
  var asMagenta     : String { return color(.magenta) }
  var asCyan        : String { return color(.cyan) }
  var asGray        : String { return color(.gray) }
  var asDefault     : String { return color(.`default`) }
  var asDarkGray    : String { return color(.darkGray) }
  var asLightRed    : String { return color(.lightRed) }
  var asLightGreen  : String { return color(.lightGreen) }
  var asYellow      : String { return color(.yellow) }
  var asLightBlue   : String { return color(.lightBlue) }
  var asLightMagenta: String { return color(.lightMagenta) }
  var asLightCyan   : String { return color(.lightCyan) }
  var asWhite       : String { return color(.white) }

  /* ––––– text coloring (256) ––––– */
  // Look at https://jonasjacek.github.io/colors/ for list of 256 xterm colors

  func foreColor(_ aColor: UInt8) -> String {
    guard !self.isEmpty && (1...255 ~= aColor) else { return self }

    if isOpenedColor {
      return CSI+"\(ANSIAttr.fore256Color.rawValue);5;\(aColor)m" + self
    }
    else {
      return CSI+"\(ANSIAttr.fore256Color.rawValue);5;\(aColor)m" + self +
             CSI+"\(ANSIAttr.`default`.rawValue)m"
    }
  }

  func withForeColor(_ aColor: UInt8) -> String { return foreColor(aColor) }

  func backColor(_ aColor: UInt8) -> String {
    guard !self.isEmpty && (1...255 ~= aColor) else { return self }

    if isOpenedColor {
      return CSI+"\(ANSIAttr.back256Color.rawValue);5;\(aColor)m" + self
    }
    else {
      return CSI+"\(ANSIAttr.back256Color.rawValue);5;\(aColor)m" + self +
             CSI+"\(ANSIAttr.onDefault.rawValue)m"
    }
  }

  func withBackColor(_ aColor: UInt8) -> String { return backColor(aColor) }

  func colors(_ fore: UInt8, _ back: UInt8) -> String {
    guard !self.isEmpty && (1...255 ~= fore) && (1...255 ~= back) else { return self }

    if isOpenedColor {
      return CSI+"\(ANSIAttr.fore256Color.rawValue);5;\(fore)m" +
             CSI+"\(ANSIAttr.back256Color.rawValue);5;\(back)m" + self
    }
    else {
      return CSI+"\(ANSIAttr.fore256Color.rawValue);5;\(fore)m" +
             CSI+"\(ANSIAttr.back256Color.rawValue);5;\(back)m" + self +
             CSI+"\(ANSIAttr.`default`.rawValue);\(ANSIAttr.onDefault.rawValue)m"
    }
  }

  func withColors(_ fore: UInt8, _ back: UInt8) -> String { return colors(fore, back) }
}

/* ––––––––––– PUBLIC FUNCTIONS –––––––––– */

public extension _ANSIScreenInterface {
    func setStyle(_ style: ANSIAttr = .normal) {
      guard (1...9 ~= style.rawValue || 21...29 ~= style.rawValue) else { return }
        terminal.write(CSI+"\(style.rawValue)m")
      isOpenedStyle = true
    }
    
    func setColor(fore: ANSIAttr = .`default`, back: ANSIAttr = .onDefault) {
      // check for foreground color value
      if (fore.rawValue >= 30 && fore.rawValue <= 37) ||
         (fore.rawValue >= 90 && fore.rawValue <= 97) ||
         (fore.rawValue == ANSIAttr.`default`.rawValue) {
          terminal.write(CSI+"\(fore.rawValue)m") }
      // check for background color value
      if (back.rawValue >=  40 && back.rawValue <=  47) ||
         (back.rawValue >= 100 && back.rawValue <= 107) ||
         (back.rawValue == ANSIAttr.onDefault.rawValue) {
          terminal.write(CSI+"\(back.rawValue)m") }
      isOpenedColor = true
    }
    
    func setColors(_ fore: UInt8, on back: UInt8) {
      guard (1...255 ~= fore) && (1...255 ~= back) else { return }
        terminal.write(CSI+"\(ANSIAttr.fore256Color.rawValue);5;\(fore)m" +
            CSI+"\(ANSIAttr.back256Color.rawValue);5;\(back)m")
      isOpenedColor = true
    }
    
    func setDefault(color: Bool = true, style: Bool = false) {
      if color {
          terminal.write(CSI+"\(ANSIAttr.`default`.rawValue);\(ANSIAttr.onDefault.rawValue)m")
        isOpenedColor = false
      }
      if style {
          terminal.write(CSI+"\(ANSIAttr.normal.rawValue)m")
        isOpenedStyle = false
      }
    }
}

// convert foreground color to background color

extension ANSIAttr {
    var asBack: ANSIAttr {
        if (rawValue >= 30 && rawValue <= 37) ||
           (rawValue >= 90 && rawValue <= 97) ||
           (rawValue == ANSIAttr.onDefault.rawValue) {
          return ANSIAttr(rawValue: rawValue+10)!
        }
        else { return self }
    }
    
    var asFore: ANSIAttr {
        if (rawValue >=  40 && rawValue <=  47) ||
           (rawValue >= 100 && rawValue <= 107) ||
           (rawValue == ANSIAttr.onDefault.rawValue) {
          return ANSIAttr(rawValue: rawValue-10)!
        }
        else { return self }
    }
    
    static func strip(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var txt = text.split(separator: NonPrintableChar.escape.char())
        for (i, sub) in txt.enumerated() {
          if let end = sub.firstIndex(of: "m") {
            txt[i] = sub[sub.index(after: end)...]
          }
        }
        return txt.joined()
    }
}
