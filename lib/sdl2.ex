defmodule SDL2 do
  def start(title, window_x, window_y) do
    SimpleSDL2.create_window(title, window_x, window_y)

    sdl2_pid = spawn(&loop/0)
    Process.register(sdl2_pid, :sdl2)
  end

  defp loop() do
    receive do
      {:render, nx_array} ->
        SimpleSDL2.update_image(nx_array)

      msg ->
        IO.inspect(msg, label: "[SDL2] Received an unknown message")
    end

    case SimpleSDL2.will_window_close?() do
      true ->
        IO.puts("[SDL2] Window closing. Exiting process.")
        :ok

      false ->
        loop()
    end
  end
end
