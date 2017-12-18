defmodule SurveyTool.Parse do

  @moduledoc """
  Parse survey and response CSV files.
  """

  alias SurveyTool.Summary.Question

  @doc """
  Parse a survey CSV file to a list of `Question` structs.

  The first line must contain column names (a header line.)
  The file must include columns named "type", "theme" and "text".
  """
  def read_survey(filename) do
    filename
    |> File.stream!
    |> CSV.decode!(headers: true, preprocessor: :none)
    |> Enum.with_index(0)
    |> Enum.map(&parse_question/1)
    |> valid_survey
  end

  defp parse_question({%{ "theme" => theme, "type" => type, "text" => text }, index}),
    do: %Question{ theme: theme, type: type, text: text, index: index }
  defp parse_question(_),
    do: throw bad_survey: "the survey file must contain columns 'type', 'theme' and 'text'"

  defp valid_survey([%Question{} | _] = questions), do: questions
  defp valid_survey(_), do: throw bad_survey: "the survey must contain at least one question"

  @doc """
  Parse a responses CSV file to a stream of lists.

  Since the number of columns depends on the survey questions, we cannot use
  a list of known column headings. Instead, columns are matched up with questions
  during processing in the `Summary` module.
  """
  def read_responses(filename) do
    filename
    |> File.stream!
    |> CSV.decode!(headers: false, preprocessor: :none)
  end

end
