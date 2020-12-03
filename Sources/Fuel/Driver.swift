import Foundation

import AST
import Basic
import Lexer
import Parser
import Sema

/// A driver that runs a pipeline of compilation actions.
public final class Driver {

  public init(
    sourceManager: SourceManager,
    pipeline: [CompilerAction],
    context: CompilerContext = CompilerContext()
  ) {
    self.pipeline = pipeline
    self.sourceManager = sourceManager
    self.context = context
  }

  /// Create a new compilation driver.
  public convenience init(pipeline: [CompilerAction] = []) throws {
    self.init(
      sourceManager: try SourceManager(),
      pipeline: pipeline,
      context: CompilerContext())
  }

  /// The driver's pipeline.
  public var pipeline: [CompilerAction]

  /// The driver's source manager.
  public let sourceManager: SourceManager

  /// The driver's compiler context.
  public let context: CompilerContext

  /// The driver's AST.
  public var module: Module?

  /// Executes the driver's pipeline.
  public func execute() throws {
    for action in pipeline {
      try execute(action: action)
    }
    pipeline.removeAll()
  }

  /// Executes the given action.
  ///
  /// - Parameter: A compiler action.s
  public func execute(action: CompilerAction) throws {
    switch action {
    case .parse(let url):
      try parse(url: url)

    case .runSema:
      runSema()
    }
  }

  public func parse(url: URL) throws {
    Parser.initialize()

    let lexer = Lexer(source: try sourceManager.load(contentsOf: url))
    let tokens = Array(lexer)

    guard case .success(let decls, _) = Parser.decls.parse(tokens[0...]) else { return }
    module = Module(
      id: url.absoluteString,
      typeDecls: [],
      funcDecls: decls)
  }

  public func runSema() {
    guard let module = self.module else { return }

    let p0 = NameBinder(compilerContext: context)
    p0.visit(module)
    let p1 = TypeRealizer(compilerContext: context)
    p1.visit(module)
    let p2 = TypeChecker(compilerContext: context)
    p2.visit(module)
  }

}
