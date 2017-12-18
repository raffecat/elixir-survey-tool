defmodule SurveyTool.SummaryTest do
  use ExUnit.Case, async: true
  doctest SurveyTool

  alias SurveyTool.Summary
  alias SurveyTool.Summary.{Question,Rating}

  describe "rating questions:" do

    @question [%Question{type: "ratingquestion", text: "Q1", theme: "T", index: 0}]

    test "average rating is zero with no responses" do
      stats = Summary.generate_stats(@question, [])
      rating = stats.ratings[0] || %Rating{}
      assert Rating.average(rating) == 0
    end

    test "average rating is correct with only one response" do
      stats = Summary.generate_stats(@question, [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "3"], # submitted, has rating.
      ])
      rating = stats.ratings[0] || %Rating{}
      assert Rating.average(rating) == 3
    end

    test "average rating is correct with duplicate responses" do
      stats = Summary.generate_stats(@question, [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "4"], # submitted, has rating.
        ["bar@example.com", "2", "2017-12-17T10:18:44+00:00", "4"], # submitted, same rating.
      ])
      rating = stats.ratings[0] || %Rating{}
      assert Rating.average(rating) == 4
    end

    test "average rating correctly computes the average" do
      stats = Summary.generate_stats(@question, [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "1"], # submitted, has rating.
        ["bar@example.com", "2", "2017-12-17T10:18:44+00:00", "5"], # submitted, has rating.
      ])
      rating = stats.ratings[0] || %Rating{}
      assert Rating.average(rating) == 3 # average: (1 + 5) / 2 = 3
    end

    test "only submitted responses are included in the rating" do
      stats = Summary.generate_stats(@question, [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "1"], # submitted, has rating.
        ["bar@example.com", "2", "", "5"] # not submitted, has rating.
      ])
      rating = stats.ratings[0] || %Rating{}
      assert Rating.average(rating) == 1
    end

    test "an empty answer does not affect the rating" do
      stats = Summary.generate_stats(@question, [
        ["foo@example.com", "1", "2017-12-17T10:18:44+00:00", "4"], # submitted, has rating.
        ["bar@example.com", "2", "2017-12-17T10:18:44+00:00", ""], # submitted, empty rating.
      ])
      rating = stats.ratings[0] || %Rating{}
      assert Rating.average(rating) == 4
    end

  end

end
