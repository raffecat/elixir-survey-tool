defmodule SurveyTool.Summary do

  @moduledoc """
  Compute summary information from survey responses.
  """

  alias SurveyTool.Models.{Question,Stats,Rating}

  @doc """
  Calculate summary information from survey responses.

  - Questions should be an enumerable of %Question{}
  - Responses should be an enumerable of [ email, employee, submitted | answers ]
  """
  def generate_stats(questions, responses) do
    try do
      aggregates = questions |> Enum.map(&aggregate_for_question/1)
      stats = %Stats{aggregates: aggregates}

      responses
      |> Enum.reduce(stats, &accumulate_response/2)
    rescue
      NimbleCSV.ParseError -> {:error, "parse error in response csv file"}
    catch
      {:error, _} = err -> err # thrown parse errors.
    end
  end

  @doc """
  Generate the appropriate initial aggregate value for a question.
  """
  def aggregate_for_question(%Question{type: "ratingquestion"}), do: %Rating{}
  def aggregate_for_question(_), do: nil

  @doc """
  Accumulate response counts and per-question aggregate values.
  """
  def accumulate_response([ _email, _employee, "" = _submitted | _ ], stats) do
    %Stats{ stats | total: stats.total + 1 } # response was not submitted.
  end
  def accumulate_response([ _email, _employee, _submitted | answers ], stats) do
    %Stats{ stats | total: stats.total + 1,
                    submitted: stats.submitted + 1,
                    aggregates: aggregates_for_answers(answers, stats.aggregates) }
  end
  def accumulate_response(_tuple, _stats) do
    throw {:error, "missing column in response csv file (email, employee, submitted)"}
  end

  @doc """
  Compute new aggregates for each question-answer pair in one response row.
  """
  def aggregates_for_answers(answers, aggregates) do
    answers
    |> verify_length(aggregates)
    |> Enum.zip(aggregates)
    |> Enum.map(&accumulate_answer/1)
  end

  @doc """
  Verify that the length of the answer list matches the number of questions (via aggregates)
  """
  def verify_length(answers, aggregates) when length(answers) == length(aggregates),
    do: answers
  def verify_length(_, _),
    do: throw {:error, "wrong number of answer columns in response csv file"}

  @doc """
  Accumulate aggregate stats for one answer to one question.

  - rating-question => accumulate rating averages.
  - other questions => accumulate nothing.
  """
  def accumulate_answer({"" = _answer, aggregate}), do: aggregate # question was not answered.
  def accumulate_answer({answer, %Rating{count: count, sum: sum}}) do
     %Rating{count: count + 1, sum: sum + parse_rating(answer)}
  end
  def accumulate_answer({_, aggregate}), do: aggregate # other question types.

  @doc """
  Parse and validate the answer to a rating-question.

  The answer must be an integer between 1 and 5 inclusive.
  """
  def parse_rating(answer) do
    case Integer.parse(answer) do
      { value, <<>> } when value >= 1 and value <= 5 -> value
      _ -> throw {:error, "malformed answer to rating question in response csv file"}
    end
  end

end
