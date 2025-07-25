defmodule ElixirLS.LanguageServer.Providers.ImplementationTest do
  use ExUnit.Case, async: true

  alias ElixirLS.LanguageServer.Providers.Implementation
  alias ElixirLS.LanguageServer.SourceFile
  alias ElixirLS.LanguageServer.Test.FixtureHelpers
  alias ElixirLS.LanguageServer.Test.ParserContextBuilder
  require ElixirLS.Test.TextLoc
  import ElixirLS.LanguageServer.RangeUtils

  test "find implementations" do
    # force load as currently only loaded or loadable modules that are a part
    # of an application are found
    Code.ensure_loaded?(ElixirLS.LanguageServer.Fixtures.ExampleBehaviourImpl)

    file_path = FixtureHelpers.get_path("example_behaviour.ex")
    parser_context = ParserContextBuilder.from_path(file_path)
    uri = SourceFile.Path.to_uri(file_path)

    {line, char} = {0, 43}

    ElixirLS.Test.TextLoc.annotate_assert(file_path, line, char, """
    defmodule ElixirLS.LanguageServer.Fixtures.ExampleBehaviour do
                                               ^
    """)

    {line, char} =
      SourceFile.lsp_position_to_elixir(parser_context.source_file.text, {line, char})

    assert {:ok, [%GenLSP.Structures.Location{uri: ^uri, range: range}]} =
             Implementation.implementation(uri, parser_context, line, char, File.cwd!())

    assert range == range(5, 0, 13, 3)
  end
end
