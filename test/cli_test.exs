defmodule SurveyTool.CLITest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  doctest SurveyTool

  alias SurveyTool.CLI

  setup do
    { :ok, questions_csv: Path.expand("./fixtures/questions.csv", __DIR__),
           responses_csv: Path.expand("./fixtures/responses.csv", __DIR__),
           missing_file: Path.expand("./fixtures/no-such-file.csv", __DIR__) }
  end

  test "works with a simple survey", context do
    output = capture_io(fn ->
      CLI.main [context[:questions_csv], context[:responses_csv]]
    end)
    assert output |> String.contains?("General question.") # from fixtures/questions.csv
  end

  test "displays usage with incorrect arguments" do
    output = capture_io(fn ->
      CLI.main []
    end)
    assert output |> String.starts_with?("usage:")
  end

  test "reports survey file not found", context do
    output = capture_io(fn ->
      CLI.main [context[:missing_file], context[:responses_csv]]
    end)
    assert output |> String.contains?("not found")
  end

  test "reports responses file not found", context do
    output = capture_io(fn ->
      CLI.main [context[:questions_csv], context[:missing_file]]
    end)
    assert output |> String.contains?("not found")
  end

end
