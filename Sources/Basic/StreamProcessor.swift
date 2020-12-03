/// A type that processes a stream to extract information.
///
/// This protocol offers a set of methods to parse a stream of data.
public protocol StreamProcessor {

  associatedtype Stream: Collection

  /// The input stream.
  var input: Stream { get }

  /// The index from which the next data should be extracted.
  var index: Stream.Index { get set }

  /// Returns the element one position ahead, without consuming the stream.
  func peek() -> Stream.Element?

  /// Returns the sequence of up to `n` elements ahead, without consuming the stream.
  ///
  /// - Parameter n: A positive offset.
  func peek(n: Int) -> Stream.SubSequence

  /// Returns the longest sequence of elements ahead that satisfy the given predicate.
  ///
  /// - Parameter predicate: A closure that accepts a single stream element and returns whether it
  ///   should be included.
  func peek(while predicate: (Stream.Element) -> Bool) -> Stream.SubSequence

  /// Consumes the next element from the stream.
  @discardableResult
  mutating func take() -> Stream.Element?

  /// Consumes up to `n` elements from the stream.
  ///
  /// - Parameter n: A positive offset.
  @discardableResult
  mutating func take(n: Int) -> Stream.SubSequence

  /// Consumes elements from the stream as long as they satisfy the given predicate.
  ///
  /// - Parameter predicate: A closure that accepts a single stream element and returns whether it
  ///   should be consumed.
  @discardableResult
  mutating func take(while predicate: (Stream.Element) -> Bool) -> Stream.SubSequence

}

extension StreamProcessor {

  public func peek() -> Stream.Element? {
    return (index < input.endIndex) ? input[index] : nil
  }

  public func peek(n: Int) -> Stream.SubSequence {
    return input[index...].prefix(n)
  }

  public func peek(while predicate: (Stream.Element) -> Bool) -> Stream.SubSequence {
    return input.suffix(from: index).prefix(while: predicate)
  }

  @discardableResult
  public mutating func take() -> Stream.Element? {
    guard index < input.endIndex else {
      return nil
    }

    let element = input[index]
    index = input.index(after: index)
    return element
  }

  @discardableResult
  public mutating func take(n: Int) -> Stream.SubSequence {
    let elements = input.suffix(from: index).prefix(n)
    index = input.index(index, offsetBy: elements.count)
    return elements
  }

  @discardableResult
  public mutating func take(while predicate: (Stream.Element) -> Bool) -> Stream.SubSequence {
    var end = index
    while end < input.endIndex && predicate(input[end]) {
      end = input.index(after: end)
    }

    let elements = input[index ..< end]
    index = end
    return elements
  }

}
