defmodule SurveyTool.CLI do

  @moduledoc """
  Entry point for the survey_tool command line application.
  """

  alias SurveyTool.Parse
  alias SurveyTool.Summary
  alias SurveyTool.Report

  @doc """
  Escript entry point.
  """
  def main(args) do
    case run_report(args) do
      {:error, msg} = err ->
        IO.puts :stderr, msg
        err
      report ->
        IO.puts report
        :ok
    end
  end

  defp run_report([survey_path, responses_path]) do
    with {:ok, questions} <- Parse.read_survey(survey_path),
         {:ok, responses} <- Parse.read_responses(responses_path)
    do
      Summary.generate_stats(questions, responses)
      |> Report.generate(questions, survey_path, responses_path)
    else
      err -> err
    end
  end
  defp run_report(_) do
    {:error, "usage: survey_tool <survey.csv> <responses.csv>"}
  end

end
