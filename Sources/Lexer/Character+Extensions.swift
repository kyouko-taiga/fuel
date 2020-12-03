extension Character {

  var isDigit: Bool {
    guard let ascii = asciiValue
      else { return false }
    return (48 ... 57) ~= ascii
  }

}
