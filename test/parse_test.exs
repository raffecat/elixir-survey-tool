defmodule SurveyTool.ParseTest do
  use ExUnit.Case, async: true
  doctest SurveyTool

  alias SurveyTool.Parse
  alias SurveyTool.Models.{Question}

  defp mock_stream(text) do
    {:ok, pid} = StringIO.open(text)
    IO.binstream(pid, :line)
  end

  describe "parse questions:" do

    test "can parse a question csv file" do
      [
        %Question{ theme: "A Theme", type: "ratingquestion", text: "Please rate." },
        %Question{ theme: "Two", type: "singleselect", text: "General question." }
      ] =
        Path.expand("./fixtures/questions.csv", __DIR__)
        |> Parse.read_survey
    end

    test "can parse question columns in any order" do
      [
        %Question{ theme: "A Theme", type: "ratingquestion", text: "Please rate." },
        %Question{ theme: "Two", type: "singleselect", text: "General question." }
      ] =
        """
        text,type,theme
        Please rate.,ratingquestion,A Theme
        "General question.",singleselect,Two
        """
        |> mock_stream
        |> Parse.parse_survey
    end

    test "rejects an empty file" do
      catch_throw "" |> mock_stream |> Parse.parse_survey
    end

    test "rejects a file with no questions" do
      catch_throw \
        """
        type,theme,text
        """
        |> mock_stream
        |> Parse.parse_survey
    end

    test "rejects a file with missing type, theme or text" do
      catch_throw \
        """
        theme,text
        A Theme,Please rate.
        Two,"General question."
        """
        |> mock_stream
        |> Parse.parse_survey
    end

  end

  describe "parse responses:" do

    test "can parse a responses csv file" do
      [
        ["foo@example.com","1","2017-12-17T10:18:44+00:00","1","2","3"],
        ["bar@example.com","2","2017-12-17T12:18:44+00:00","4","5","6"]
      ] =
        Path.expand("./fixtures/responses.csv", __DIR__)
        |> Parse.read_responses
        |> Enum.to_list
    end

    test "can parse an empty responses file" do
      [] =
        """
        """
        |> mock_stream
        |> Parse.parse_responses
        |> Enum.to_list
    end

    test "rejects a file with uneven rows" do
      catch_error \
        """
        foo@example.com,1,2017-12-17T10:18:44+00:00,1,2,3
        bar@example.com,2,2017-12-17T12:18:44+00:00,4,5
        """
        |> mock_stream
        |> Parse.parse_responses
        |> Enum.to_list
    end

  end

end
