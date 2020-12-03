import Fuel

import AST
import Basic
import Lexer
import Parser
import Sema

func main() throws {
//  let input = """
//  // func f(_: UnsafeMutablePointer<Int>) {}
//  fn f : \\A a .(!a + [a: Int] -> !void + [a: Int]) {
//
//  }
//
//  // func g(_: Int, _: Bool) -> Bool {}
//  fn g : { Int, Bool } -> Bool
//
//  fn main : { Int } -> Int {
//    x = salloc &((Int))
//    y = salloc &(!a + [a: Int] -> Int)
//
//    // Some comment.
//    store $0, x
//
//    if true {
//      z = load y
//    } else {
//      z = load x
//    }
//
//    store $1, a
//  }
//  """

  // Create a source manager. This class is responsible for loading and caching source files.
  let sourceManager = try SourceManager()

  // Create a compiler context. This class is responsible for handling various objects throughout
  // all compilation stages (e.g., types).
  let context = CompilerContext()
  context.diagnosticConsumer = Console(sourceManager: sourceManager)

  let input = try sourceManager.load(contentsOf: "Hello.fuel")

  let lexer = Lexer(source: input)
  let tokens = Array(lexer)

  Parser.initialize()
  switch Parser.decls.parse(tokens[0...]) {
  case .success(let decls, let rem):
    if rem.first?.kind != .eof {
      print("error: the parser didn't consume the entire stream.")
      print(rem.first as Any)
    } else {
      // print(decls[0])
    }

    // Create a module from all the parsed declarations.
    let module = Module(
      id: "main",
      typeDecls: [],
      funcDecls: decls)

    // Run the semantic analysis.
    let nameBinder = NameBinder(compilerContext: context)
    nameBinder.visit(module)
    let typeRealizer = TypeRealizer(compilerContext: context)
    typeRealizer.visit(module)
    let typeChecker = TypeChecker(compilerContext: context)
    typeChecker.visit(module)

  case .failure(let error):
    print(error)
  }
}

try main()
