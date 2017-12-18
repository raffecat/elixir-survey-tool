defmodule SurveyTool.CLI do

  @moduledoc """
  Entry point for your command line application.
  """

  alias SurveyTool.Parse
  alias SurveyTool.Summary
  alias SurveyTool.Report

  def main(args) do
    try do
      run_report(args)
    catch
      bad_survey: msg -> IO.puts msg
    end
  end

  def run_report([survey, responses]) do
    unless File.regular?(survey), do: throw bad_survey: "not found: #{survey}"
    unless File.regular?(responses), do: throw bad_survey: "not found: #{responses}"

    questions = Parse.read_survey(survey)
    response_stream = Parse.read_responses(responses)

    Summary.generate_stats(questions, response_stream)
    |> Report.display(questions, survey, responses)
  end
  def run_report(_) do
    IO.puts "usage: survey_tool <survey.csv> <responses.csv>"
  end

end
