defmodule SurveyTool.ReportTest do
  use ExUnit.Case, async: true
  doctest SurveyTool

  alias SurveyTool.Report
  alias SurveyTool.Models.{Question,Stats,Rating}

  @u_question %Question{type: "unknown-question-type", text: "Unknown Question?", theme: "T"}
  @r_question %Question{type: "ratingquestion", text: "Rating Question?", theme: "T"}
  @s_question %Question{type: "singleselect", text: "Single Select Question?", theme: "T"}

  describe "general:" do

    test "empty report renders without error" do
      report = Report.generate(%Stats{}, [], "xyz", "abc")
      assert report |> String.contains?("Survey Report")
    end

    test "can render unknown question types" do
      stats = %Stats{total: 0, submitted: 0, aggregates: [nil]}
      report = Report.generate(stats, [@u_question], "xyz", "abc")
      assert report |> String.contains?(@u_question.text)
    end

    test "can render with no participation" do
      stats = %Stats{total: 10, submitted: 0, aggregates: [nil]}
      report = Report.generate(stats, [@u_question], "xyz", "abc")
      assert report |> String.contains?("(0.0%)")
    end

    test "can render with 50% participation" do
      stats = %Stats{total: 10, submitted: 5, aggregates: [nil]}
      report = Report.generate(stats, [@u_question], "xyz", "abc")
      assert report |> String.contains?("(50.0%)")
    end

    test "can render with 100% participation" do
      stats = %Stats{total: 10, submitted: 10, aggregates: [nil]}
      report = Report.generate(stats, [@u_question], "xyz", "abc")
      assert report |> String.contains?("(100.0%)")
    end

    test "can render with multiple questions without responses" do
      stats = %Stats{total: 0, submitted: 0, aggregates: [nil, %Rating{count: 0, sum: 0}, nil]}
      report = Report.generate(stats, [@u_question, @r_question, @s_question], "xyz", "abc")
      assert report |> String.contains?(@u_question.text)
      assert report |> String.contains?(@r_question.text)
      assert report |> String.contains?(@s_question.text)
    end

    test "can render with multiple questions with responses" do
      stats = %Stats{total: 10, submitted: 10, aggregates: [nil, %Rating{count: 10, sum: 30}, nil]}
      report = Report.generate(stats, [@u_question, @r_question, @s_question], "xyz", "abc")
      assert report |> String.contains?(@u_question.text)
      assert report |> String.contains?(@r_question.text)
      assert report |> String.contains?(@s_question.text)
    end

  end

  describe "rating questions:" do

    test "can render a ratingquestion with no responses" do
      stats = %Stats{total: 0, submitted: 0, aggregates: [%Rating{count: 0, sum: 0}]}
      report = Report.generate(stats, [@r_question], "xyz", "abc")
      assert report |> String.contains?(@r_question.text)
      assert report |> String.contains?("average rating: 0.0 from 0 responses")
    end

    test "can render a ratingquestion with one response" do
      stats = %Stats{total: 1, submitted: 1, aggregates: [%Rating{count: 1, sum: 4}]}
      report = Report.generate(stats, [@r_question], "xyz", "abc")
      assert report |> String.contains?(@r_question.text)
      assert report |> String.contains?("average rating: 4.0 from 1 responses")
    end

    test "can render a ratingquestion with many responses" do
      stats = %Stats{total: 10, submitted: 9, aggregates: [%Rating{count: 9, sum: 9*3}]}
      report = Report.generate(stats, [@r_question], "xyz", "abc")
      assert report |> String.contains?(@r_question.text)
      assert report |> String.contains?("average rating: 3.0 from 9 responses")
    end

  end

  describe "single select questions:" do

    test "can render a singleselect with no responses" do
      stats = %Stats{total: 0, submitted: 0, aggregates: [nil]}
      report = Report.generate(stats, [@s_question], "xyz", "abc")
      assert report |> String.contains?(@s_question.text)
    end

    test "can render a singleselect with one response" do
      stats = %Stats{total: 1, submitted: 1, aggregates: [nil]}
      report = Report.generate(stats, [@s_question], "xyz", "abc")
      assert report |> String.contains?(@s_question.text)
    end

    test "can render a singleselect with many responses" do
      stats = %Stats{total: 10, submitted: 9, aggregates: [nil]}
      report = Report.generate(stats, [@s_question], "xyz", "abc")
      assert report |> String.contains?(@s_question.text)
    end

  end

end
