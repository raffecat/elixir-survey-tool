defmodule SurveyTool.Mixfile do
  use Mix.Project

  def project do
    [
      app: :survey_tool,
      version: "0.1.1",
      elixir: "~> 1.5",
      escript: [main_module: SurveyTool.CLI],
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_csv, "~> 0.4.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
end
