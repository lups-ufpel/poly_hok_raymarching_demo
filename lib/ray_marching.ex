require PolyHok

PolyHok.defmodule RayMarching do
  # Magnitude de um vetor 3D
  defd lenght(v_x, v_y, v_z) do
    return(sqrt(v_x * v_x + v_y * v_y + v_z * v_z))
  end

  # Cálculo de distancia euclidiana entre dois pontos 3D
  defd distance(p1_x, p1_y, p1_z, p2_x, p2_y, p2_z) do
    dx = p1_x - p2_x
    dy = p1_y - p2_y
    dz = p1_z - p2_z
    return(sqrt(dx * dx + dy * dy + dz * dz))
  end

  # Produto escalar entre dois vetores 3D
  defd dot(v1_x, v1_y, v1_z, v2_x, v2_y, v2_z) do
    return(1.0 * (v1_x * v2_x + v1_y * v2_y + v1_z * v2_z))
  end

  # Sphere Signed Distance Function (SDF)
  # A distância de um ponto p até a superfície de uma esfera é a distância do ponto p
  # para o centro da esfera menos o raio da esfera.
  # Os argumentos dessa função são um ponto p (p_x, p_y, p_z) e os parâmetros da esfera (center_x, center_y, center_z, radius).
  defd sphere_sdf(p_x, p_y, p_z, center_x, center_y, center_z, radius) do
    # Calcula a distância do ponto p para o centro da esfera usando a função de distância euclidiana
    l = distance(p_x, p_y, p_z, center_x, center_y, center_z)
    # Subtrai o raio da esfera
    return(l - radius)
  end

  # Polynomial Smooth Minimum Function
  # Essa função é usada para combinar as SDFs de múltiplos objetos de forma suave, criando uma transição
  # suave tipo "líquido" quando os objetos se aproximam um do outro.
  # Recebe as distâncias d1 e d2 e um fator k que controla a suavidade da transição.
  # Quanto maior for k, mais suave será a transição.
  defd smooth_min(d1, d2, k) do
    # Calcula o fator de interpolação 'h'
    h = 0.5 + 0.5 * (d2 - d1) / k
    # Clampa 'h' para o intervalo [0, 1]
    h = clamp(h, 0.0, 1.0)

    # Retorna a distância combinada usando interpolação polinomial
    mix_val = h * d1 + (1.0 - h) * d2
    return(mix_val - k * h * (1.0 - h))
  end

  # 3D map of the scene, returns the distance to the closest object
  # Receives a point p (p_x, p_y, p_z) and returns the distance to the closest object in the scene
  # to that point
  defd scene_sdf(p_x, p_y, p_z, time) do
    # Sphere 1
    s1_x = 0.0
    s1_z = -1.0
    s1_y = -fabs(sin(time * 5.0) * 0.5) + 0.2
    s1_radius = 0.5

    # Sphere 2
    s2_x = cos(time * 3.0) * 0.5
    s2_y = sin(time * 4.0)
    s2_z = -1.0
    s2_radius = 0.2

    # Calculate the distance to each sphere using the sphere SDF
    sphere_1_distance = sphere_sdf(p_x, p_y, p_z, s1_x, s1_y, s1_z, s1_radius)
    sphere_2_distance = sphere_sdf(p_x, p_y, p_z, s2_x, s2_y, s2_z, s2_radius)

    # Smoothly combine the distances to the two spheres using the smooth minimum function
    return(smooth_min(sphere_1_distance, sphere_2_distance, 0.3))
  end

  # Ray marching function
  # Receives a ray origin (ray_origin_x, ray_origin_y, ray_origin_z) and a ray direction (ray_dir_x, ray_dir_y, ray_dir_z)
  # and returns the distance traveled along the ray until it hits an object or reaches a maximum distance
  defd ray_march(ray_origin_x, ray_origin_y, ray_origin_z, ray_dir_x, ray_dir_y, ray_dir_z, time) do
    total_distance = 0.0

    # Far clip plane
    max_distance = 100.0

    max_steps = 64

    # Minimum distance to consider a hit
    min_distance = 0.001

    for i in range(0, max_steps) do
      # Calculate the current point along the ray
      current_x = ray_origin_x + ray_dir_x * total_distance
      current_y = ray_origin_y + ray_dir_y * total_distance
      current_z = ray_origin_z + ray_dir_z * total_distance

      # Get the distance to the closest object from the current point
      dist_to_closest = scene_sdf(current_x, current_y, current_z, time)

      if dist_to_closest < min_distance do
        # Hit an object
        return(total_distance)
      end

      if total_distance > max_distance do
        # Exceeded maximum distance without hitting anything
        # Indicate no hit with a negative value
        return(-1.0)
      end

      # Move along the ray by the distance to the closest object
      total_distance = total_distance + dist_to_closest
    end

    # If we perform the maximum number of steps without hitting anything, we also consider it a miss
    return(-1.0)
  end

  defk render_kernel(img_array, dim_x, dim_y, time, fov) do
    tid_x = get_global_id(0)
    tid_y = get_global_id(1)

    if tid_x < dim_x && tid_y < dim_y do
      # Creating UV coordinates normalized to [-1, 1]
      u = 2.0 * (1.0 * tid_x / (1.0 * dim_x)) - 1.0
      v = 2.0 * (1.0 * tid_y / (1.0 * dim_y)) - 1.0
      # Aspect ratio correction for x coordinate
      u = u * (1.0 * dim_x / (1.0 * dim_y))
      # FOV correction
      fov_correction = tan(fov / 2.0)
      u = u * fov_correction
      v = v * fov_correction

      # Set up camera position (ray origin)
      cam_x = 0.0
      cam_y = 0.0
      cam_z = 1.0

      # Ray direction (where the camera is looking at)
      # The camera is looking towards the negative z direction
      ray_dir_x = u - cam_x
      ray_dir_y = v - cam_y
      ray_dir_z = -1.0

      # Normalize ray direction
      ray_dir_len = lenght(ray_dir_x, ray_dir_y, ray_dir_z)
      ray_dir_x = ray_dir_x / ray_dir_len
      ray_dir_y = ray_dir_y / ray_dir_len
      ray_dir_z = ray_dir_z / ray_dir_len

      # Perform ray marching
      dist = ray_march(cam_x, cam_y, cam_z, ray_dir_x, ray_dir_y, ray_dir_z, time)

      if dist > 0.0 do
        # We hit something!
        # Calculate the point of intersection
        hit_x = cam_x + ray_dir_x * dist
        hit_y = cam_y + ray_dir_y * dist
        hit_z = cam_z + ray_dir_z * dist

        # Let's do some lighting calculation =D
        # I'll add a simple directional light pointing to (0, 1, -1)
        light_dir_x = 0.0
        light_dir_y = 1.0
        light_dir_z = -5.0
        # Normalize light direction
        light_dir_len = lenght(light_dir_x, light_dir_y, light_dir_z)
        light_dir_x = light_dir_x / light_dir_len
        light_dir_y = light_dir_y / light_dir_len
        light_dir_z = light_dir_z / light_dir_len

        # Calculate the normal at the hit point using the gradient of the SDF
        epsilon = 0.001
        n_x = scene_sdf(hit_x + epsilon, hit_y, hit_z, time) - scene_sdf(hit_x - epsilon, hit_y, hit_z, time)
        n_y = scene_sdf(hit_x, hit_y + epsilon, hit_z, time) - scene_sdf(hit_x, hit_y - epsilon, hit_z, time)
        n_z = scene_sdf(hit_x, hit_y, hit_z + epsilon, time) - scene_sdf(hit_x, hit_y, hit_z - epsilon, time)

        # Normalize the normal
        n_len = lenght(n_x, n_y, n_z)
        n_x = n_x / n_len
        n_y = n_y / n_len
        n_z = n_z / n_len

        # Calculate the diffuse lighting using the dot product between the normal and the light direction
        brightness = -dot(n_x, n_y, n_z, light_dir_x, light_dir_y, light_dir_z)
        # Clamp to [0, 1]
        brightness = min(max(brightness, 0.0), 1.0)

        # Color phase
        phase = fabs(sin(time * 2.0))

        # Base colors
        color_r = 100.0
        color_g = 100.0 * phase
        color_b = 255.0 * (1.0 - phase)

        # Applying brightness to each color channel
        final_r = trunc(brightness * color_r)
        final_g = trunc(brightness * color_g)
        final_b = trunc(brightness * color_b)

        final_color = (final_r * 0x10000) + (final_g * 0x100) + final_b
        img_array[tid_y * dim_x + tid_x] = final_color
      else
        # If we didn't hit anything, set the pixel to black
        img_array[tid_y * dim_x + tid_x] = 0x000000
      end
    end
  end

  defp render_loop(gpu_array, dim_x, dim_y, fps) do
    start_time = System.monotonic_time()

    threads_per_block = 16
    blocks_x = div(dim_x + threads_per_block - 1, threads_per_block)
    blocks_y = div(dim_y + threads_per_block - 1, threads_per_block)

    {time, _} = :erlang.statistics(:wall_clock)
    time = time / 1000.0

    # FOV (field of view) in degrees, converted to radians
    fov = 60.0 * (:math.pi() / 180.0)

    # Lançando o kernel de renderização na GPU
    PolyHok.spawn(
      &RayMarching.render_kernel/5,
      {blocks_x, blocks_y, 1},
      {threads_per_block, threads_per_block, 1},
      [gpu_array, dim_x, dim_y, time, fov]
    )

    # Pega o resultado da renderização na GPU e envia para o processo do SDL2 para atualizar a textura
    result_ram = gpu_array |> PolyHok.get_gnx()
    send(:sdl2, {:render, result_ram})

    end_time = System.monotonic_time()

    render_time_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)
    max_time_ms = (1.0 / fps) * 1000.0

    if (render_time_ms < max_time_ms) do
      Process.sleep(floor(max_time_ms - render_time_ms))
    end

    # Recursão para continuar o loop de renderização
    render_loop(gpu_array, dim_x, dim_y, fps)
  end

  def start_render(dim_x, dim_y, fps) do
    gpu_array = PolyHok.new_gnx({dim_x, dim_y}, :s32)

    render_worker_pid = spawn(fn -> render_loop(gpu_array, dim_x, dim_y, fps) end)

    sdl_monitor_ref = Process.whereis(:sdl2) |> Process.monitor

    receive do
      {:DOWN, ^sdl_monitor_ref, :process, _pid, _reason} ->
        # Se o processo do SDL for encerrado, saímos do loop de renderização lindamente =)
        IO.puts("[RayMarching] SDL process has terminated. Stopping render loop.")

        Process.demonitor(sdl_monitor_ref, [:flush])

        # Kill render worker to ensure it doesn't keep running in the background
        if Process.alive?(render_worker_pid) do
          Process.exit(render_worker_pid, :kill)
        end

        :ok
    end
  end
end
