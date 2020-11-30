/// A reference to an aggregate's member.
public final class MemberExpr: Expr {

  /// Creates a reference to an aggregate's member.
  ///
  /// - Parameters:
  ///   - base: A reference to an aggregate.
  ///   - offset: A o-based offset in the aggregate.
  public init(base: Expr, offset: Int) {
    self.base = base
    self.offset = offset
  }

  /// A reference to the aggregate.
  public var base: Expr

  /// A o-based offset in the aggregate.
  public var offset: Int

  public var range: SourceRange?

  public func accept<V>(_ visitor: V) where V: Visitor {
    visitor.visit(self)
  }

}

extension MemberExpr: CustomStringConvertible {

  public var description: String {
    return "\(base).\(offset)"
  }

}
