import Foundation

import AST
import Basic
import Lexer
import Parser
import Sema

/// A driver that runs a pipeline of compilation actions.
public final class Driver {

  /// Create a new compilation driver.
  public init(
    moduleID: String,
    sourceManager: SourceManager = SourceManager(),
    pipeline: [CompilerAction] = [],
    astContext: ASTContext = ASTContext()
  ) {
    self.module = Module(id: moduleID, context: astContext)

    self.pipeline = pipeline
    self.sourceManager = sourceManager
    self.astContext = astContext
  }

  /// The driver's module.
  public let module: Module

  /// The driver's pipeline.
  public var pipeline: [CompilerAction]

  /// The driver's source manager.
  public let sourceManager: SourceManager

  /// The driver's AST context.
  public let astContext: ASTContext

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
    let lexer = Lexer(source: try sourceManager.load(contentsOf: url))
    var parser = Parser(astContext: astContext, input: lexer)

    var decls: [FuncDecl] = []
    while let decl = parser.parseTopLevelDecl() {
      decls.append(decl)
    }

    module.merge(funcDecls: decls)
  }

  public func runSema() {
    let p0 = NameBinder(astContext: astContext)
    p0.visit(module)
    let p1 = TypeRealizer(astContext: astContext)
    p1.visit(module)
    let p2 = TypeChecker(astContext: astContext)
    p2.visit(module)
  }

}
