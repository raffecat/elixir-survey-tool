defmodule SurveyTool.Parse do

  @moduledoc """
  Parse survey and response CSV files.
  """

  defmodule Question do
    defstruct [:theme, :type, :text]
  end

  defmodule Stats do
    defstruct total: 0, submitted: 0, ratings: %{}
  end

  defmodule Rating do
    defstruct count: 0, sum: 0
  end

  # alias NimbleCSV.RFC4180, as: CSV
  # |> CSV.parse_stream(headers: false) # false -> include the first row.

  @doc """
  Parse a survey CSV file to a stream of maps,
  where the first line is expected to contain field names (headers)
  """
  def read_survey(filename) do
    # consider: need to be able to test with CSV heredocs.
    # consider: what to do if there are no questions?
    filename
    |> File.stream!
    |> CSV.decode!(headers: true, preprocessor: :none)
    |> Enum.map(&parse_survey_row/1)
  end

  def parse_survey_row(row) do
    case row do
      %{ "theme" => theme, "type" => type, "text" => text } -> %Question{ theme: theme, type: type, text: text }
      _ -> raise "missing required field in survey row"
    end
  end

  @doc """
  Parse a responses CSV file to a stream of lists.
  Since the number of columns depends on the survey questions
  """
  def stream_responses(filename) do
    # consider: want to stream responses in case there are a great many of them.
    # consider: what to do if there are not enough response columns?
    # consider: what to do if there are extra response columns?
    filename
    |> File.stream!
    |> CSV.decode!(headers: false, preprocessor: :none)
  end

  @doc """
  Accumulate the rating average for one rating-question and answer.
  """
  def accumulate_rating(ratings, index, answer) do
    case Integer.parse(answer) do
      { value, <<>> } when value >= 1 and value <= 5 ->
        current = ratings[index] || %Rating{}
        Map.put(ratings, index, %Rating{
          count: current.count + 1,
          sum: current.sum + value })
      _ -> throw "bad answer to rating question"
    end
  end

  @doc """
  Accumulate rating averages for each rating-question in one survey response row.
  """
  def ratings_for_response(q_types, answers, in_ratings) do
    # TODO: zip will stop early (skip questions) if answers are missing.
    Enum.reduce(Enum.zip(q_types, answers), in_ratings, fn { { q_type, index }, answer }, ratings ->
      case q_type do
        "ratingquestion" -> case answer do
          "" -> ratings # question was not answered.
          _ -> accumulate_rating(ratings, index, answer)
        end
        _ -> ratings # other question types.
      end
    end)
  end

  @doc """
  Calculate summary information from survey responses.
  Questions should be an enumerable of %Question{}
  Responses should be an enumerable of { email, employee, submitted | answers }
  """
  def response_stats(questions, responses) do
    q_types = Enum.with_index(Enum.map(questions, fn q -> q.type end))
    Enum.reduce(responses, %Stats{}, fn row, stats ->
      case row do
        [ _email, _employee, submitted | answers ] ->
          { add_submit, new_ratings } = case submitted do
            "" -> { 0, stats.ratings } # response was not submitted.
             _ -> { 1, ratings_for_response(q_types, answers, stats.ratings) }
          end
          %Stats{ total: stats.total + 1,
                  submitted: stats.submitted + add_submit,
                  ratings: new_ratings }
        _ -> raise "missing required field in response row"
      end
    end)
  end

end
