class Light
  constructor: (x, y, z) ->
    @light_vector = Vector.create([x, y, z])
    @ka = 0.2
    @kd = 0.5
    @kr = 0.8
    @n = 7

  reflection_vector: (normale_vector) ->
    return ((normale_vector.cross(@light_vector)).cross(normale_vector).x(2)).subtract(@light_vector)

  ambient: (intensity) ->
    return intensity

  diffuse: (normale_vector, intensity) ->
    # Надо учитывать, что если косинус больше Пи/2, то угол равен 0
    alpha = Math.cos_ab( normale_vector, @light_vector )  
    if alpha < 0
      return 0
    else
      return Math.max(intensity * alpha)

  reflect: (normale_vector, intensity) ->
    # HACK::: !!!
    reflection_vector = this.reflection_vector( normale_vector )
    alpha = reflection_vector.e(3) / Math.vector_length( reflection_vector )
    if alpha < 0
      return 0
    else
      return Math.pow( alpha, @n ) * intensity

  # i - intensity
  summary_intensity: ( ambient_i, diffuse_i, reflection_i, surf_i, normale_vector ) ->
    a_i = Math.min(ambient_i, surf_i)
    d_i = Math.min(diffuse_i, surf_i)
    return (@ka * this.ambient( a_i ) + @kd * this.diffuse(normale_vector, d_i) + @kr * this.reflect(normale_vector, reflection_i)) 

  set_x_coord: (val) ->
    @light_vector.setElements( [val, @light_vector.e(2), @light_vector.e(3)] )

  set_y_coord: (val) ->
    @light_vector.setElements( [@light_vector.e(1), val, @light_vector.e(3)] )

  set_z_coord: (val) ->
    @light_vector.setElements( [@light_vector.e(1), @light_vector.e(2), val] )

  set_ka: (val) ->
    @ka = val

  set_kd: (val) ->
    @kd = val

  set_kr: (val) ->
    @kr = val

  set_n: (val) ->
    @n = val

window.Light = Light