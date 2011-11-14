# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

Number::mod = (n) -> ((this % n) + n) % n

class Point
  constructor: (x, y, z, a, b, c) ->
    @x = x
    @y = y
    @z = z

    @x_angle = a
    @y_angle = b
    @z_angle = c

    @xSize = 2000
    @ySize = 1000
    @central_project = false

  sin_A: ( a ) ->
    return Math.sin( a )
    if (a == 0 && b == 0)
      return 0
    return a / Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) )

  sin_B: ( c ) ->
    return Math.sin( c )
    if (a==0 && b==0 && c==0)
      return 0
    return Math.sqrt(Math.pow(a, 2) + Math.pow(b, 2) ) / Math.sqrt( Math.pow(b, 2) + Math.pow(c, 2) + Math.pow(a, 2) )

  cos_A: ( a ) ->
    return Math.cos( a )
    if (a==0 && b==0)
      return 1
    return b / Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) )

  cos_B: ( c ) ->
    return Math.cos(c)
    if (a==0 && b==0 && c==0)
      return 1
    return c / Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) + Math.pow(c, 2) )

  calculate_sin_cos: () ->
    @sin_a = this.sin_A( @x_angle )
    @cos_a = this.cos_A( @x_angle )
    @sin_b = this.sin_B( @z_angle )
    @cos_b = this.cos_B( @z_angle )
    @sin_c = Math.sin( @y_angle )
    @cos_c = Math.cos( @y_angle )

  get_matrixes: () ->
    @rotate_z  = Matrix.create([
                           [ @cos_a, @sin_a,  0, 0],
                           [ -@sin_a, @cos_a,   0, 0],
                           [ 0, 0, 1, 0],
                           [ 0, 0, 0, 1]])

    @rotate_x  = Matrix.create([
                         [ 1, 0, 0, 0],
                         [ 0, @cos_b, @sin_b, 0],
                         [ 0, -@sin_b,  @cos_b, 0],
                         [ 0, 0, 0, 1] ])

    @rotate_y  = Matrix.create([
                         [ @cos_c, 0, -@sin_c, 0],
                         [ 0, 1, 0, 0],
                         [ @sin_c, 0,  @cos_c, 0],
                         [ 0, 0, 0, 1] ])

    @move_xy   = Matrix.create([ [1,0,0,0],
                         [0,1,0,0],
                         [0,0,1,0],
                         [@xSize, @ySize,0,1] ])

    @project_xy = $M([ [1,0,0,0],
                          [0,1,0,0],
                          [0,0,0,0],
                          [0,0,0,1] ])

    dist = Math.sqrt(Math.pow(@x_angle, 2) + Math.pow(@y_angle, 2) + Math.pow(@z_angle, 2))

    @central_pr =      $M([ [1,0,0,0],
                         [0,1,0,0],
                         [0,0,1,-1/dist],
                         [0,0,0,1] ])


  get_screen_projection: () ->
    this.calculate_sin_cos()
    this.get_matrixes()
    point = $M([[@x, @y, @z, 1]])
    rotate     = (@rotate_z.x(@rotate_x)).x(@rotate_y)

    if @central_project == true
      centr_math = ((point.x(rotate)).x(@central_pr)).x(@move_xy)
      nnx_c = centr_math.e(1,1)/centr_math.e(1,4)
      nny_c = centr_math.e(1,2)/centr_math.e(1,4)
      sx = nnx_c
      sy = nny_c
    else
      orth_math  = (point.x(rotate)).x(@move_xy)
      sx = orth_math.e(1,1)
      sy = orth_math.e(1,2)

    return [sx/10, sy/10]

class PseudoSphere
  constructor: (u_min, v_min, u_max, v_max) ->
    @u_max = u_max
    @v_max = v_max
    @u_min = u_min
    @v_min = v_min

    @x_angle = 354*Math.PI/180
    @y_angle = 303*Math.PI/180
    @z_angle = 208*Math.PI/180

    @du = 0.18
    @dv = 0.28
    @surface_parameter = -2
    @dist = 0

    @to_newel = new Array()
    @flat = false

  set_camera: (xang, yang, zang) ->
    @z_angle = xang
    @y_angle = yang
    @x_angle = zang

  set_camera_x_angle: ( val ) ->
    @x_angle = val*Math.PI/180

  set_camera_y_angle: ( val ) ->
    @y_angle = val*Math.PI/180

  set_camera_z_angle: ( val ) ->
    @z_angle = val*Math.PI/180

  set_du: ( val ) ->
    @du = val

  set_dv: ( val ) ->
    @dv = val

  set_u: ( val ) ->

  set_v: ( val ) ->

  set_flat: ( val ) ->
    @flat = val

  set_surface_parameter: ( val ) ->
    @surface_parameter = val

  point_equation: ( u, v ) ->
    a = @surface_parameter
    x = a * Math.sin( u ) * Math.cos( v ) * 1000
    y = a * Math.sin( u ) * Math.sin( v ) * 1000
    z = a * ( Math.log( Math.tan( u / 2 ) ) + Math.cos( u ) ) * 1000
#    x = u * Math.cos( v )*1000
#    y = u * Math.sin( v )*1000
#    z = a * v * 1000
#    x = ( r + Math.cos( u / 2 ) * Math.sin( v ) - Math.sin( u / 2 ) * Math.sin( 2 * v )  ) * Math.cos( u ) * 1000
#    y = ( r + Math.cos( u / 2 ) * Math.sin( v ) - Math.sin( u / 2 ) * Math.sin( 2 * v )  ) * Math.sin( u ) * 1000
#    z = ( Math.sin( u / 2 ) * Math.sin( v ) + Math.cos( u / 2 ) * Math.sin( 2 * v )  ) * 1000
    return [x, y, z]

  sphere_3d_points: () ->
    points = []
    u_min = @u_min
    v_min = @v_min
    u_max = @u_max
    v_max = @v_max

    cnts = []
    while u_min < u_max
      while v_min < v_max
        points.push( this.point_equation(u_min, v_min) )
        v_min += @dv
      u_min += @du
      v_min = @v_min
    @dist = Math.round(Math.abs(@v_max - @v_min) / @dv)
    @du_count = Math.round(Math.abs(@u_max - @u_min) / @du)
    return points

  # В итоге делаем так:
  # Каждой точек ставим в соответствие её 3d точку
  # Потом когда находим сегменты, берем 4 первые точки
  # и берем соответствующие ей 3d координаты
  # и считаем для каждой коэффициенты a, b, c

  sphere_screen_points: () ->
    points = this.sphere_3d_points()
    screen_points = []

    for point in points
      to_p = new Point( point[0], point[1], point[2], @x_angle, @y_angle, @z_angle )
      to_p = to_p.get_screen_projection()
      @to_newel[to_p] = [ point[0], point[1], point[2] ]
      screen_points.push( to_p )
    return screen_points

  sphere_segments: () ->
    points = this.sphere_screen_points()
    segments = []
    for i in [0...points.length - @dist - 1]
      segments.push([ points[i],  points[i + @dist + 1], points[i + @dist], points[i]])

    for j in [0...@du_count]
      ind = (@dist + 1)*j
      if ind + @dist + 1 <= points.length-1
        segments[ind] = [ points[ind], points[ind + @dist], points[ind], points[ind + @dist + 1]]

    return segments

  fill_segment: (segment) ->
    if @flat
      a = 0
      b = 0
      c = 0
      j = 0

      for i in [0...segment.length - 1]
        if i == segment.length - 2
          j = 1
        else
          j = i + 1
        first_surf_point = @to_newel[ segment[i] ]
        second_surf_point = @to_newel[ segment[j] ]
        if first_surf_point != undefined && second_surf_point != undefined
          a += (first_surf_point[1] - second_surf_point[1]) * (first_surf_point[2] + second_surf_point[2])
          b += (first_surf_point[2] - second_surf_point[2]) * (first_surf_point[0] + second_surf_point[0])
          c += (first_surf_point[0] - second_surf_point[0]) * (first_surf_point[1] + second_surf_point[1])

      cos_s_n = c / Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) + Math.pow(c , 2) )
      cos_s_n *= -1
      #cos_s_n = (-1)*((a*0) + (b*0) + (c*1))/ Math.sqrt( (Math.pow(0, 2) + Math.pow(0, 2) + Math.pow(1, 2))*(Math.pow(a, 2) + Math.pow(b, 2) + Math.pow(c, 2)) )
      color_in = [123, 222, 173]
      color_out = [123, 104, 238]
      color = 0
      if cos_s_n < 0
        color_in[0] *= (-cos_s_n)
        color_in[1] *= (-cos_s_n)
        color_in[2] *= (-cos_s_n)
        color = "rgb(#{color_in[0]}, #{color_in[1]}, #{color_in[2]})"
      else if cos_s_n > 0
        color_out[0] *= cos_s_n
        color_out[1] *= cos_s_n
        color_out[2] *= cos_s_n
        color = "rgb(#{color_out[0]}, #{color_out[1]}, #{color_out[2] })"

      #alert(cos_s_n)
      if color != 0
        jc.line([segment[0], segment[1], segment[2], segment[3], segment[4] ], color, 1 )


  draw: () ->
    jc.clear("canvas")
    jc.start('canvas', true)
    segments = this.sphere_segments()

    for segment in segments
      this.fill_segment(segment)
      jc.line(segment)
    jc.line(segments[(@dist + 1)*1], '#ff5587')

$ ->
  u_min = 0.0
  v_min = 0.0
  u_max = Math.PI/2
  v_max = 2*Math.PI
  sp = new PseudoSphere( u_min, v_min, u_max, v_max )
  sp.draw()

  $('#angle_x').slider
    min: 0
    max: 800
    value: 100
    slide: (event, ui) ->
      $('#angle_x p').html(ui.value)
      sp.set_camera_x_angle( ui.value )
      sp.draw()

  $('#angle_y').slider
    min: 0
    max: 800
    value: 100
    slide: (event, ui) ->
      $('#angle_y p').html(ui.value)
      sp.set_camera_y_angle( ui.value )
      sp.draw()

  $('#angle_z').slider
    min: 0
    max: 800
    value: 100
    slide: (event, ui) ->
      $('#angle_z p').html(ui.value)
      sp.set_camera_z_angle( ui.value )
      sp.draw()

   $('#u').slider
    min: 1
    max: 360
    value: 60
    slide: (event, ui) ->
      $('#u p').html(ui.value)
      sp.set_u(ui.value)
      sp.draw()

  $('#v').slider
    min: 1
    max: 360
    value: 60
    slide: (event, ui) ->
      $('#v p').html(ui.value)
      sp.set_v(ui.value)
      sp.draw()

  $('#step_u').slider
    min: 0.03
    max: 4
    step: 0.05
    value: 0.1
    slide: (event, ui) ->
      $('#step_u p').html(ui.value)
      sp.set_du(ui.value)
      sp.draw()

  $('#step_v').slider
    min: 0.03
    max: 4
    step: 0.05
    value: 0.1
    slide: (event, ui) ->
      $('#step_v p').html(ui.value)
      sp.set_dv(ui.value)
      sp.draw()

  $('#a').slider
    min: -5
    max: 5
    step: 0.01
    value: 1
    slide: (event, ui) ->
      $('#a p').html(ui.value)
      sp.set_surface_parameter(ui.value)
      sp.draw()

  $("input[name='filling']").change ->
    if ($("input[@name='filling']:checked").val() == 'frame')
      sp.set_flat(false)
      sp.draw()
    else if ($("input[@name='filling']:checked").val() == 'flat')
      sp.set_flat(true)
      sp.draw()
    else
      sp.set_flat(false)
      sp.draw()

