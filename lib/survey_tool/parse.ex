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
    case File.open(filename) do
      {:ok, file} -> parse_survey(file)
      {:error, _} -> {:error, "cannot read: #{filename}"}
    end
  end

  @doc """
  Parse a survey CSV file to a list of `Question` structs.

  - The first line must contain column names (a header line.)
  - The file must include columns named "type", "theme" and "text".
  """
  def parse_survey(device) do
    try do
      device
      |> IO.binstream(:line)
      |> CSV.parse_stream(headers: false) # false -> don't discard first row!
      |> Enum.to_list
      |> parse_survey_rows
    rescue
      NimbleCSV.ParseError -> {:error, "parse error in survey csv file"}
    catch
      {:error, _} = err -> err # thrown parse error.
    end
  end

  defp parse_survey_rows([]), do: {:error, "the survey file cannot be empty"}
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
    do: throw {:error, "the survey file must contain columns 'type', 'theme' and 'text'"}

  defp valid_survey([%Question{} | _] = questions), do: {:ok, questions}
  defp valid_survey([]), do: {:error, "the survey must contain at least one question"}

  @doc """
  Read a responses CSV file and parse to a stream of lists.
  """
  def read_responses(filename) do
    case File.open(filename) do
      {:ok, file} -> parse_responses(file)
      {:error, _} -> {:error, "cannot read: #{filename}"}
    end
  end

  @doc """
  Parse a responses CSV file to a stream of lists.

  Since the number of columns depends on the survey questions, we cannot use
  a list of known column headings. Instead, columns are matched up with questions
  during processing in the `Summary` module.
  """
  def parse_responses(device) do
    device
    |> IO.binstream(:line)
    |> CSV.parse_stream(headers: false) # false -> don't discard first row!
    |> (&({:ok, &1})).()
  end

end
