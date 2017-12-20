defmodule SurveyTool.Models do

  @moduledoc """
  Models for survey questions and summary information.
  """

  defmodule Question do

    @moduledoc """
    Survey `Question` struct with fields: `theme`, `type`, `text`.
    """

    defstruct [:theme, :type, :text]

  end

  defmodule Stats do

    @moduledoc """
    Summary `Stats` struct with fields: `total`, `submitted`, `aggregates`.
    """

    defstruct total: 0, submitted: 0, aggregates: []

    @doc """
    Calculate the participation percentage from accumulated `total` and `submitted` counts.
    """
    def participation(stats) do
      if stats.total > 0 do stats.submitted / stats.total else 0.0 end
    end
  end

  defmodule Rating do

    @moduledoc """
    Aggregate `Rating` struct with fields: `count`, `sum`.
    """

    defstruct count: 0, sum: 0

    @doc """
    Calculate the average rating from accumulated `sum` and `count`.
    """
    def average(rating) do
      if rating.count > 0 do rating.sum / rating.count else 0.0 end
    end
  end

end
