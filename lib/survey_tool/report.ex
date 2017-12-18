defmodule SurveyTool.Report do

  @moduledoc """
  Generate and display a survey summary report.
  """

  alias SurveyTool.Summary.{Question,Stats,Rating}

  def display(stats, questions, survey_file, response_file) do
    IO.puts """
    Survey Report

      Questions from: #{survey_file}
      Responses from: #{response_file}\
    """
    participation_summary(stats)
    question_summaries(questions, stats)
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
    for { question, index } <- Enum.with_index(questions) do
      question_summary question, index, stats
    end
  end

  @doc """
  Display an appropriate summary for one question based on its type.
  """
  def question_summary(%Question{type: "ratingquestion"} = question, index, stats) do
    rating = stats.ratings[index] || %Rating{}
    average = Float.round(Rating.average(rating), 2)

    IO.puts """
      #{question.theme}: #{question.text}
        average rating: #{average} from #{rating.count} responses
    """
  end
  def question_summary(question, _index, _stats) do
    IO.puts """
      #{question.theme}: #{question.text}
    """
  end

end
