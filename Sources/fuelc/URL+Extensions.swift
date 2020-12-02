import Foundation

extension URL {

  /// Returns a path that resolves to this URL, relative to a given path.
  ///
  /// - Parameter other: The path of the directory to which the returned path will be relative.
  func path(relativeTo other: String) -> String {
    let lhs = pathComponents
    let rhs = URL(fileURLWithPath: other).pathComponents

    var i = 0
    while (i < Swift.min(lhs.count, rhs.count)) && (lhs[i] == rhs[i]) {
      i += 1
    }

    let rel = [String](repeating: "..", count: rhs.count - i)
    let rem = lhs.dropFirst(i).map(String.init(describing:))
    if rel.isEmpty && rem.isEmpty {
      return "."
    } else {
      return (rel + rem).joined(separator: "/")
    }
  }

}
