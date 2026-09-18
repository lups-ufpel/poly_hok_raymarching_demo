defmodule RaymarchingDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :raymarching_demo,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
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
    {:nx, "~> 0.9"},
    {:poly_hok, git: "https://github.com/lups-ufpel/poly_hok.git", sparse: "poly_hok"},
    {:opencl_backend, git: "https://github.com/lups-ufpel/poly_hok.git", sparse: "backends/opencl_backend"},
    {:simple_sdl2, git: "https://github.com/lups-ufpel/simple_sdl_for_elixir.git"}
  ]
  end
end
