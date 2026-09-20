use RayMarching

window_x = 500
window_y = 600

argv = System.argv()
fps =
  if length(argv) >= 1 do
    String.to_integer(hd(argv))
  else
    60
  end

SDL2.start("Ray Marching Demo", window_x, window_y)
RayMarching.start_render(window_x, window_y, fps)
