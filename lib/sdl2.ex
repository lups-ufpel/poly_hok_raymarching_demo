defmodule SDL2 do
  def start(title, window_x, window_y) do
    SimpleSDL2.create_window(title, window_x, window_y)

    sdl2_pid = spawn(fn -> loop(System.monotonic_time(), 0, 0.0) end)
    Process.register(sdl2_pid, :sdl2)
  end

  defp loop(last_render_time, fps, acc_elapsed_ms) do
    {last_render_time, fps, acc_elapsed_ms} =
      receive do
        {:render, nx_array} ->
          SimpleSDL2.update_image(nx_array)

          render_time = System.monotonic_time()
          elapsed_ms = System.convert_time_unit(render_time - last_render_time, :native, :millisecond)

          acc_elapsed_ms = acc_elapsed_ms + elapsed_ms
          fps = fps + 1

          {fps, acc_elapsed_ms} =
            if acc_elapsed_ms >= 1000.0 do
              IO.puts("[SDL2] FPS: #{fps}")

              {0, 0.0}
            else
              {fps, acc_elapsed_ms}
            end

          {render_time, fps, acc_elapsed_ms}

        msg ->
          IO.inspect(msg, label: "[SDL2] Received an unknown message")

          {last_render_time, fps, acc_elapsed_ms}
      end

    case SimpleSDL2.will_window_close?() do
      true ->
        IO.puts("[SDL2] Window closing. Exiting process.")
        :ok

      false ->
        loop(last_render_time, fps, acc_elapsed_ms)
    end
  end
end
