defmodule SurveyTool.Report do

  @moduledoc """
  Generate a survey summary report.
  """

  alias SurveyTool.Models.{Stats,Rating}

  @doc """
  Generate a survey summary report.
  """
  def generate(stats, questions, survey_path, response_path) do
    """
    Survey Report

      Questions from: #{survey_path}
      Responses from: #{response_path}
      #{participation_summary(stats)}

    #{question_summaries(questions, stats)}
    """
  end

  @doc """
  Generate a summary of the level of participation in the survey.
  """
  def participation_summary(stats) do
    participation = Float.round(Stats.participation(stats) * 100, 2)

    "Participation: #{stats.submitted} of #{stats.total} responses were submitted (#{participation}%)"
  end

  @doc """
  Generate a summary of all questions asked in the survey.
  """
  def question_summaries(questions, stats) do
    questions
    |> Enum.zip(stats.aggregates)
    |> Enum.zip(Stream.cycle([stats]))
    |> Enum.map(&question_summary/1)
    |> Enum.join("\n")
  end

  @doc """
  Generate an appropriate summary for one question based on its type.
  """
  def question_summary({{question, %Rating{} = rating}, _stats}) do
    average = Float.round(Rating.average(rating), 2)

    """
      #{question.theme}: #{question.text}
        average rating: #{average} from #{rating.count} responses
    """
  end
  def question_summary({{question, _aggregate}, _stats}) do
    """
      #{question.theme}: #{question.text}
        (#{question.type})
    """
  end

end
