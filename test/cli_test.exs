defmodule SurveyTool.CLITest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  doctest SurveyTool

  alias SurveyTool.CLI

  setup_all do
    { :ok, questions_csv: Path.expand("./fixtures/questions.csv", __DIR__),
           responses_csv: Path.expand("./fixtures/responses.csv", __DIR__),
           missing_file: Path.expand("./fixtures/no-such-file.csv", __DIR__) }
  end

  test "works with a simple survey", context do
    capture_io(fn ->
      assert :ok = CLI.main [context[:questions_csv], context[:responses_csv]]
    end)
  end

  test "displays usage with incorrect arguments" do
    capture_io(:stderr, fn ->
      assert {:error, "usage:" <> _} = CLI.main []
    end)
  end

  test "reports survey file not found", context do
    capture_io(:stderr, fn ->
      assert {:error, "cannot read:" <> _} = CLI.main [context[:missing_file], context[:responses_csv]]
    end)
  end

  test "reports responses file not found", context do
    capture_io(:stderr, fn ->
      assert {:error, "cannot read:" <> _} = CLI.main [context[:questions_csv], context[:missing_file]]
    end)
  end

end
