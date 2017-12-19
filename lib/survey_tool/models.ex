defmodule SurveyTool.Models do

  @moduledoc """
  Models for survey data.
  """

  defmodule Question do
    defstruct [:theme, :type, :text]
  end

  defmodule Stats do
    defstruct total: 0, submitted: 0, aggregates: []

    @doc """
    Calculate the participation percentage from accumulated total and submitted count.
    """
    def participation(stats) do
      if stats.total > 0 do stats.submitted / stats.total else 0.0 end
    end
  end

  defmodule Rating do
    defstruct count: 0, sum: 0

    @doc """
    Calculate the average rating from accumulated rating sum and count.
    """
    def average(rating) do
      if rating.count > 0 do rating.sum / rating.count else 0.0 end
    end
  end

end
