/// The identifier of a particular memory segment  .
public enum MemorySegment {

  /// The stack segment.
  ///
  /// This segment typically contains local, temporary data.
  case stack

  /// The heap segment.
  ///
  /// This segment typically contains shared, long-living data.
  case heap

}
