import Foundation

struct FileOutputStream: TextOutputStream {

  init(handle: FileHandle) {
    self.handle = handle
  }

  let handle: FileHandle

  func write(_ string: String) {
    if let data = string.data(using: .utf8) {
      handle.write(data)
    }
  }

  static let stdout = FileOutputStream(handle: FileHandle.standardOutput)

  static let stderr = FileOutputStream(handle: FileHandle.standardError)

}
