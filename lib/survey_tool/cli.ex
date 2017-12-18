defmodule SurveyTool.CLI do

  alias SurveyTool.Parse

  @moduledoc """
  Entry point for your command line application.
  """

  def main(args) do
    try do
      case args do
        [survey, responses] -> summary(survey, responses)
        _ -> IO.puts "usage: survey_tool <survey.csv> <responses.csv>"
      end
    catch
      msg -> IO.puts msg
    end
  end

  def summary(survey_file, response_file) do
    if ! File.regular?(survey_file), do: throw "not found: #{survey_file}"
    if ! File.regular?(response_file), do: throw "not found: #{response_file}"
    questions = Parse.read_survey(survey_file)
    responses = Parse.stream_responses(response_file)
    stats = Parse.response_stats(questions, responses)
    IO.puts """
    Survey Report

      Questions from: #{survey_file}
      Responses from: #{response_file}\
    """
    participation_summary(stats)
    question_summaries(stats, questions)
  end

  def participation_summary(stats) do
    participation = rounded_percentage(stats.submitted, stats.total)
    IO.puts """
      Participation: #{stats.submitted} of #{stats.total} responses were submitted (#{participation}%)
    """
  end

  def question_summaries(stats, questions) do
    for { question, index } <- Enum.with_index(questions) do
      case question.type do
        "ratingquestion" -> rating_question_summary(stats, question, index)
        _ -> other_question_summary(stats, question, index)
      end
    end
  end

  def rating_question_summary(stats, question, index) do
    rating = stats.ratings[index] || %Parse.Rating{}
    avg = if rating.count > 0 do rating.sum / rating.count else 0 end
    IO.puts """
      #{question.theme}: #{question.text}
        average rating is #{Float.round(avg,2)} from #{rating.count} responses.
    """
  end

  def other_question_summary(stats, question, index) do
    IO.puts """
      #{question.theme}: #{question.text}
    """
  end

  @doc """
  Safely divide fraction of total and round for display as a percenatage.
  """
  def rounded_percentage(fraction, total) do
    percentage = if total > 0 do fraction / total else 0 end
    rounded = Float.round(percentage * 100, 2)
  end

end
