defmodule SurveyTool.Parse do

  @moduledoc """
  Parse survey and response CSV files.
  """

  alias NimbleCSV.RFC4180, as: CSV
  alias SurveyTool.Models.Question

  @doc """
  Read a survey CSV file and parse a list of `Question` structs.
  """
  def read_survey(filename) do
    filename
    |> File.stream!
    |> parse_survey
  end

  @doc """
  Parse a survey CSV stream to a list of `Question` structs.

  The first line must contain column names (a header line.)
  The file must include columns named "type", "theme" and "text".
  """
  def parse_survey(stream) do
    stream
    |> CSV.parse_stream(headers: false) # false -> don't discard first row!
    |> Enum.to_list
    |> parse_survey_rows
  end

  defp parse_survey_rows([]), do: throw bad_survey: "the survey file cannot be empty"
  defp parse_survey_rows([ header | rows ]) do
    rows
    |> Enum.zip(Stream.cycle([header])) # [{row,header},..]
    |> Enum.map(&row_to_map/1)
    |> Enum.map(&parse_question/1)
    |> valid_survey
  end

  defp row_to_map({row, header}) do
    header
    |> Enum.zip(row)
    |> Enum.into(%{})
  end

  defp parse_question(%{ "theme" => theme, "type" => type, "text" => text }),
    do: %Question{ theme: theme, type: type, text: text }
  defp parse_question(%{}),
    do: throw bad_survey: "the survey file must contain columns 'type', 'theme' and 'text'"

  defp valid_survey([%Question{} | _] = questions), do: questions
  defp valid_survey([]), do: throw bad_survey: "the survey must contain at least one question"

  @doc """
  Read a responses CSV file and parse to a stream of lists.
  """
  def read_responses(filename) do
    filename
    |> File.stream!
    |> parse_responses
  end

  @doc """
  Parse a responses CSV file to a stream of lists.

  Since the number of columns depends on the survey questions, we cannot use
  a list of known column headings. Instead, columns are matched up with questions
  during processing in the `Summary` module.
  """
  def parse_responses(stream) do
    stream
    |> CSV.parse_stream(headers: false) # false -> don't discard first row!
  end

end
