defmodule SurveyTool.Summary do

  @moduledoc """
  Compute summary information from survey responses.
  """

  defmodule Question do
    defstruct [:theme, :type, :text, :index]
  end

  defmodule Stats do
    defstruct total: 0, submitted: 0, ratings: %{}

    def participation(stats) do
      if stats.total > 0 do stats.submitted / stats.total else 0 end
    end
  end

  defmodule Rating do
    defstruct count: 0, sum: 0

    def average(rating) do
      if rating.count > 0 do rating.sum / rating.count else 0 end
    end
  end

  @doc """
  Calculate summary information from survey responses.

  Questions should be an enumerable of %Question{}
  Responses should be an enumerable of [ email, employee, submitted | answers ]
  """
  def generate_stats(questions, responses) do
    Enum.reduce(responses, %Stats{}, fn row, stats ->
      case row do
        [ _email, _employee, submitted | answers ] ->
          { add_submit, new_ratings } = case submitted do
            "" -> { 0, stats.ratings } # response was not submitted.
             _ -> { 1, ratings_for_response(questions, answers, stats.ratings) }
          end
          %Stats{ total: stats.total + 1,
                  submitted: stats.submitted + add_submit,
                  ratings: new_ratings }
        _ -> throw bad_survey: "missing answer column in response rows"
      end
    end)
  end

  @doc """
  Accumulate rating averages for each rating-question in one survey response row.
  """
  def ratings_for_response(questions, answers, ratings) do
    # TODO: zip will stop early (skip questions) if answers are missing.
    Enum.reduce(Enum.zip(questions, answers), ratings, fn { question, answer }, ratings ->
      stats_for_question(question, answer, ratings)
    end)
  end

  @doc """
  Accumulate stats for each question in one survey response row.

  rating-question => accumulate rating averages.
  other questions => accumulate nothing.
  """
  def stats_for_question(%Question{type: "ratingquestion"} = question, answer, ratings) do
    case answer do
      "" -> ratings # question was not answered.
       _ -> answer
            |> validate_rating
            |> accumulate_rating(ratings, question.index)
    end
  end
  def stats_for_question(_question, _answer, ratings), do: ratings # other question types.

  @doc """
  Validate the answer to a rating question.

  The answer must be an integer between 1 and 5 inclusive.
  """
  def validate_rating(answer) do
    case Integer.parse(answer) do
      { value, <<>> } when value >= 1 and value <= 5 -> value
      _ -> throw bad_survey: "malformed answer to rating question"
    end
  end

  @doc """
  Accumulate the rating average for one rating-question and answer.
  """
  def accumulate_rating(value, ratings, index) do
    current = ratings[index] || %Rating{}

    Map.put(ratings, index, %Rating{ count: current.count + 1,
                                     sum: current.sum + value })
  end

end
