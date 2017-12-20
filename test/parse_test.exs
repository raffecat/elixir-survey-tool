defmodule SurveyTool.ParseTest do
  use ExUnit.Case, async: true
  doctest SurveyTool

  alias SurveyTool.Parse
  alias SurveyTool.Models.{Question}

  defp mock_stream(text) do
    {:ok, device} = StringIO.open(text)
    device
  end

  describe "parse questions:" do

    test "can read a valid question csv file" do
      result =
        Path.expand("./fixtures/questions.csv", __DIR__)
        |> Parse.read_survey

      assert {:ok, [
        %Question{ theme: "A Theme", type: "ratingquestion", text: "Please rate." },
        %Question{ theme: "Two", type: "singleselect", text: "General question." }
      ]} = result
    end

    test "can parse question columns in any order" do
      result =
        """
        text,type,theme
        Please rate.,ratingquestion,A Theme
        "General question.",singleselect,Two
        """
        |> mock_stream
        |> Parse.parse_survey

      assert {:ok, [
        %Question{ theme: "A Theme", type: "ratingquestion", text: "Please rate." },
        %Question{ theme: "Two", type: "singleselect", text: "General question." }
      ]} = result
    end

    test "rejects an empty csv file" do
      assert {:error, _} =
        ""
        |> mock_stream
        |> Parse.parse_survey
    end

    test "rejects a file with no questions" do
      assert {:error, _} =
        """
        type,theme,text
        """
        |> mock_stream
        |> Parse.parse_survey
    end

    test "rejects a file with missing type column" do
      assert {:error, _} =
        """
        theme,text
        A Theme,Please rate.
        Two,"General question."
        """
        |> mock_stream
        |> Parse.parse_survey
    end

    test "rejects a file with missing theme column" do
      assert {:error, _} =
        """
        text,type,bob
        Please rate.,ratingquestion,A Theme
        "General question.",singleselect,Two
        """
        |> mock_stream
        |> Parse.parse_survey
    end

    test "rejects a file with missing text column" do
      assert {:error, _} =
        """
        bob,type,theme
        Please rate.,ratingquestion,A Theme
        "General question.",singleselect,Two
        """
        |> mock_stream
        |> Parse.parse_survey
    end

  end

  defp to_list({:error, _} = err), do: err
  defp to_list({:ok, stream}), do: stream |> Enum.to_list

  describe "parse responses:" do

    test "can read a responses csv file" do
      result =
        Path.expand("./fixtures/responses.csv", __DIR__)
        |> Parse.read_responses
        |> to_list

      assert [
        ["foo@example.com","1","2017-12-17T10:18:44+00:00","1","alice"],
        ["bar@example.com","2","2017-12-17T12:18:44+00:00","4","bob"]
      ] = result
    end

    test "can parse an empty responses csv" do
      result =
        """
        """
        |> mock_stream
        |> Parse.parse_responses
        |> to_list

      assert [] = result
    end

  end

end
