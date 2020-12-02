extension Substring {

  func occurences(of character: Character) -> Int {
    var count = 0
    for ch in self where ch == character {
      count += 1
    }
    return count
  }

}
