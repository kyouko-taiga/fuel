import Basic

public final class AllocStmt: Stmt, NamedDecl {

  public init(name: String, segment: MemorySegment, sign: TypeSign, loc: LocDecl? = nil) {
    self.name = name
    self.segment = segment
    self.sign = sign
    self.loc = loc
  }

  public var name: String

  public var segment: MemorySegment

  public var sign: TypeSign

  /// The location of the cell allocated by this statement.
  public var loc: LocDecl?

  public var declContext: DeclContext?

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension AllocStmt: CustomStringConvertible {

  public var description: String {
    let prefix: String
    switch segment {
    case .stack: prefix = "s"
    case .heap : prefix = "h"
    }

    if let loc = self.loc {
      return "\(name) = \(prefix)alloc \(sign) at \(loc.name)"
    } else {
      return "\(name) = \(prefix)alloc \(sign)"
    }
  }

}
