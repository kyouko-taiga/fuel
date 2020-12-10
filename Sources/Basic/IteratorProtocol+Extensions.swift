public struct TransformIterator<Base, Element>: IteratorProtocol where Base: IteratorProtocol {

  public init(base: Base, transform: @escaping (Base.Element) -> Element) {
    self.base = base
    self.transform = transform
  }

  public private(set) var base: Base

  public let transform: (Base.Element) -> Element

  public mutating func next() -> Element? {
    return base.next().map(transform)
  }

}

public struct ConcatenatedIterator<I1, I2>: IteratorProtocol
where I1: IteratorProtocol, I2: IteratorProtocol, I1.Element == I2.Element
{

  public typealias Element = I1.Element

  public init(_ fst: I1, _ snd: I2) {
    self.fst = fst
    self.snd = snd
  }

  public private(set) var fst: I1

  public private(set) var snd: I2

  public mutating func next() -> Element? {
    return fst.next() ?? snd.next()
  }

}

extension IteratorProtocol {

  /// Creates an iterator that applies the given closure to every elements it returns.
  ///
  /// - Parameter transform: A mapping closure. `transform` accepts an element of this iterator and
  ///   returns a transformed value.
  public func map<T>(_ transform: @escaping (Element) -> T) -> TransformIterator<Self, T> {
    return TransformIterator(base: self, transform: transform)
  }

  /// Returns the concatenation of this iterator with another.
  ///
  /// The produced iterator iterates over all elements from `fst` and then all elements from `snd`.
  ///
  /// - Parameter other: Another iterator.
  public func concatenated<T>(with other: T) -> ConcatenatedIterator<Self, T>
  where T: IteratorProtocol, T.Element == Element
  {
    return ConcatenatedIterator(self, other)
  }

}
