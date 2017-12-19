defmodule SurveyTool.SummaryTest do
  use ExUnit.Case, async: true
  doctest SurveyTool

  alias SurveyTool.Summary
  alias SurveyTool.Models.{Question,Stats,Rating}

  describe "generate stats:" do

    @gs_question %Question{type: "singleselect", text: "Q1", theme: "T"}

    test "works without any questions or responses" do
      stats = Summary.generate_stats([], [])
      assert stats.total == 0
    end

    test "works with a question but without any responses" do
      stats = Summary.generate_stats([@gs_question], [])
      assert stats.total == 0
    end

    test "counts all responses" do
      stats = Summary.generate_stats([@gs_question], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "bob"],
        ["bar@example.com", "2", "2017-12-17T10:18:44+00:00", "bob"],
        ["baz@example.com", "3", "2017-12-17T10:18:44+00:00", "bob"],
      ])
      assert stats.total == 3
    end

    test "counts submitted responses" do
      stats = Summary.generate_stats([@gs_question], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "bob"],
        ["bar@example.com", "2", "2017-12-17T10:18:44+00:00", "bob"],
        ["baz@example.com", "3", "", ""]
      ])
      assert stats.total == 3 and stats.submitted == 2
    end

    test "rejects responses with missing answer columns" do
      catch_throw Summary.generate_stats([@gs_question], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00"], # missing answer to question.
      ])
    end

    test "rejects responses with missing submitted column" do
      catch_throw Summary.generate_stats([@gs_question], [
        ["foo@example.com", "1"], # missing submitted column.
      ])
    end

  end

  describe "participation percentage:" do

    @pp_question %Question{type: "singleselect", text: "Q1", theme: "T"}

    test "zero participation for zero responses" do
      stats = Summary.generate_stats([@pp_question], [])
      assert Stats.participation(stats) == 0.0 # 0%
    end

    test "100% participation for one response" do
      stats = Summary.generate_stats([@pp_question], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "bob"],
      ])
      assert Stats.participation(stats) == 1.0 # 100%
    end

    test "100% participation for two responses" do
      stats = Summary.generate_stats([@pp_question], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "bob"],
        ["bar@example.com", "2", "2017-12-17T10:18:44+00:00", "bob"],
      ])
      assert Stats.participation(stats) == 1.0 # 100%
    end

    test "50% participation for two responses, one submitted" do
      stats = Summary.generate_stats([@pp_question], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "bob"],
        ["bar@example.com", "2", "", "bob"],
      ])
      assert Stats.participation(stats) == 0.5 # 50%
    end

  end

  describe "rating questions:" do

    @question1 %Question{type: "ratingquestion", text: "Q1", theme: "T"}
    @question2 %Question{type: "singleselect", text: "Q2", theme: "T"}

    # defp q1_rating(%Stats{ aggregates: [ rating | _ ] }), do: rating

    test "average rating is zero with no responses" do
      %Stats{ aggregates: [ rating | _ ] } = Summary.generate_stats([@question1], [])
      assert Rating.average(rating) == 0
    end

    test "average rating is correct with only one response" do
      %Stats{ aggregates: [ rating | _ ] } = Summary.generate_stats([@question1], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "3"], # submitted, has rating.
      ])
      assert Rating.average(rating) == 3
    end

    test "average rating is correct with duplicate responses" do
      %Stats{ aggregates: [ rating | _ ] } = Summary.generate_stats([@question1], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "4"], # submitted, has rating.
        ["bar@example.com", "2", "2017-12-17T10:18:44+00:00", "4"], # submitted, same rating.
      ])
      assert Rating.average(rating) == 4
    end

    test "average rating correctly computes the average" do
      %Stats{ aggregates: [ rating | _ ] } = Summary.generate_stats([@question1], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "1"], # submitted, has rating.
        ["bar@example.com", "2", "2017-12-17T10:18:44+00:00", "5"], # submitted, has rating.
      ])
      assert Rating.average(rating) == 3 # average: (1 + 5) / 2 = 3
    end

    test "only submitted responses are included in the rating" do
      %Stats{ aggregates: [ rating | _ ] } = Summary.generate_stats([@question1], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "1"], # submitted, has rating.
        ["bar@example.com", "2", "", "5"] # not submitted, has rating.
      ])
      assert Rating.average(rating) == 1
    end

    test "an empty answer does not affect the rating" do
      %Stats{ aggregates: [ rating | _ ] } = Summary.generate_stats([@question1], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "4"], # submitted, has rating.
        ["bar@example.com", "2", "2017-12-17T10:18:44+00:00", ""], # submitted, empty rating.
      ])
      assert Rating.average(rating) == 4
    end

    test "non-rating questions do not affect the rating" do
      %Stats{ aggregates: [ rating | _ ] } = Summary.generate_stats([@question1, @question2], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "4", "bob"], # submitted.
      ])
      assert Rating.average(rating) == 4
    end

    test "rejects responses with invalid ratings" do
      catch_throw Summary.generate_stats([@question1], [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "0"], # submitted, invalid rating.
      ])
    end

  end

end
