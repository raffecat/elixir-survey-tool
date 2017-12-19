defmodule SurveyTool.Report do

  @moduledoc """
  Generate and display a survey summary report.
  """

  alias SurveyTool.Models.{Stats,Rating}

  @doc """
  Generate and display a survey summary report.
  """
  def display(stats, questions, survey_file, response_file) do
    IO.puts """
    Survey Report

      Questions from: #{survey_file}
      Responses from: #{response_file}\
    """
    participation_summary(stats)
    question_summaries(questions, stats)
    :ok
  end

  @doc """
  Display a summary of the level of participation in the survey.
  """
  def participation_summary(stats) do
    participation = Float.round(Stats.participation(stats) * 100, 2)

    IO.puts """
      Participation: #{stats.submitted} of #{stats.total} responses were submitted (#{participation}%)
    """
  end

  @doc """
  Display a summary of all questions asked in the survey.
  """
  def question_summaries(questions, stats) do
    questions
    |> Enum.zip(stats.aggregates)
    |> Enum.zip(Stream.cycle([stats]))
    |> Enum.map(&question_summary/1)
  end

  @doc """
  Display an appropriate summary for one question based on its type.
  """
  def question_summary({{question, %Rating{} = rating}, _stats}) do
    average = Float.round(Rating.average(rating), 2)

    IO.puts """
      #{question.theme}: #{question.text}
        average rating: #{average} from #{rating.count} responses
    """
  end
  def question_summary({{question, _aggregate}, _stats}) do
    IO.puts """
      #{question.theme}: #{question.text}
        (#{question.type})
    """
  end

end
