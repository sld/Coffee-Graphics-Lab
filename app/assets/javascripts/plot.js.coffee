# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class Point
  constructor: (x, y, z, a, b, c) ->
    @x = x
    @y = y
    @z = z

    @x_angle = a
    @y_angle = b
    @z_angle = c

    # Для Move Matrix
    @xSize = 2800
    @ySize = 1900
    @central_project = false

  #--- Необходимо вынести в модуль Math ---#
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
  #---    ---#

    
  # calculate_sin_cos: () ->
  #   @sin_a = Math.sin( @x_angle )
  #   @cos_a = Math.cos( @x_angle )
  #   @sin_b = Math.sin( @y_angle )
  #   @cos_b = Math.cos( @y_angle )
  #   @sin_c = Math.sin( @z_angle )
  #   @cos_c = Math.cos( @z_angle )


  get_matrixes: () ->
    # @rotate_z  = Matrix.create([
    #                        [ @cos_c, @sin_c,  0, 0],
    #                        [ -@sin_c, @cos_c,   0, 0],
    #                        [ 0, 0, 1, 0],
    #                        [ 0, 0, 0, 1]])

    # @rotate_x  = Matrix.create([
    #                      [ 1, 0, 0, 0],
    #                      [ 0, @cos_a, @sin_a, 0],
    #                      [ 0, -@sin_a,  @cos_a, 0],
    #                      [ 0, 0, 0, 1] ])

    # @rotate_y  = Matrix.create([
    #                      [ @cos_b, 0, -@sin_b, 0],
    #                      [ 0, 1, 0, 0],
    #                      [ @sin_b, 0,  @cos_b, 0],
    #                      [ 0, 0, 0, 1] ])

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
  multiplicate: (matrix) ->
    point = $M([[@x, @y, @z, 1]])
    matr = point.x(matrix)
    @x = matr.e(1,1)
    @y = matr.e(1,2)
    @z = matr.e(1,3)
  
  move: (x=2800, y=1900, z=0) ->
    move_matr = Matrix.create([ [1,0,0,0],
                         [0,1,0,0],
                         [0,0,1,0],
                         [x, y, z,1] ])
    point = $M([[@x, @y, @z, 1]])
    result = point.x(move_matr)
    @x = result.e(1,1)
    @y = result.e(1,2)
    @z = result.e(1,3)

  get_screen_projection: () ->
    this.get_matrixes()
    point = $M([[@x, @y, @z, 1]])

    if @central_project == true
      centr_math = (point.x(@central_pr)).x(@move_xy)
      nnx_c = centr_math.e(1,1)/centr_math.e(1,4)
      nny_c = centr_math.e(1,2)/centr_math.e(1,4)
      sx = nnx_c
      sy = nny_c
    else
      orth_math  = point.x(@project_xy).x(@move_xy)
      
      sx = orth_math.e(1,1)
      sy = orth_math.e(1,2)

    return [sx/10, sy/10]

class PseudoSphere
  constructor: (u_min, v_min, u_max, v_max) ->
    @u_max = u_max
    @v_max = v_max
    @u_min = 0
    @v_min = 0

    @x_angle = 0*Math.PI/180
    @y_angle = 0*Math.PI/180
    @z_angle = 0*Math.PI/180

    @surface_parameter = -2
    @dv_count = 11
    @du_count = 20

    @to_newel = new Array()
    @flat = false

    @color_out = [123, 200, 20]
    @color_in = [255,255,22]

    @prev_x_angle =  @x_angle
    @prev_y_angle =  @y_angle
    @prev_z_angle =  @z_angle

    # Результирующая матрица для поворота
    @result_matr = Matrix.I(4)

  set_camera: (xang, yang, zang) ->
    @z_angle = zang
    @y_angle = yang
    @x_angle = xang
  
  # Считаем матрицу поворота. Стоит вынести за пределы текущего класса
  calc_rotate: (axis) ->
    switch axis
      when 'x'
        cos_a = Math.cos(@x_angle)
        sin_a = Math.sin(@x_angle)
        return Matrix.create([
                             [ 1, 0, 0, 0],
                             [ 0, cos_a, sin_a, 0],
                             [ 0, -sin_a,  cos_a, 0],
                             [ 0, 0, 0, 1] ])
      when 'y'
        cos_b = Math.cos(@y_angle)
        sin_b = Math.sin(@y_angle)
        return Matrix.create([
                             [ cos_b, 0, -sin_b, 0],
                             [ 0, 1, 0, 0],
                             [ sin_b, 0,  cos_b, 0],
                             [ 0, 0, 0, 1] ])
      when 'z'
        cos_c = Math.cos(@z_angle)
        sin_c = Math.sin(@z_angle)
        return Matrix.create([
                               [ cos_c, sin_c,  0, 0],
                               [ -sin_c,cos_c,   0, 0],
                               [ 0, 0, 1, 0],
                               [ 0, 0, 0, 1]])

  # Обновляем резулитриующую матрицу применяя операцию поворота( матрица = матрица*поворот_по_оси )
  rotate_result_matr: (axis) ->
    rot_matr = this.calc_rotate(axis)
    @result_matr = @result_matr.x(rot_matr)

  set_camera_x_angle: ( val ) ->
    radian = Math.PI / 180
    @x_angle = val*radian - @prev_x_angle 
    @prev_x_angle = (val*Math.PI)/180
    this.rotate_result_matr('x')

  set_camera_y_angle: ( val ) ->
    radian = Math.PI / 180
    @y_angle = val*radian - @prev_y_angle
    @prev_y_angle = val*Math.PI/180
    this.rotate_result_matr('y')

  set_camera_z_angle: ( val ) ->
    radian = Math.PI / 180
    @z_angle = val*radian - @prev_z_angle
    @prev_z_angle = val*Math.PI/180
    this.rotate_result_matr('z')

  set_du_count: ( val ) ->
    @du_count = val

  set_dv_count: ( val ) ->
    @dv_count = val

  set_u: ( val ) ->
    @u_max = val * Math.PI / 180

  set_v: ( val ) ->
    @u_min = val * Math.PI / 180

  set_flat: ( val ) ->
    @flat = val

  set_surface_parameter: ( val ) ->
    @surface_parameter = val

  set_out_color: (rgb) ->
    @color_out[0] = rgb[0]
    @color_out[1] = rgb[1]
    @color_out[2] = rgb[2]

  set_in_color: (rgb) ->
    @color_in[0] = rgb[0]
    @color_in[1] = rgb[1]
    @color_in[2] = rgb[2]

  point_equation: ( u, v ) ->
    a = @surface_parameter * 1000
    x = a * Math.sin( u ) * Math.cos( v ) 
    y = a * Math.sin( u ) * Math.sin( v ) 
    z = a * ( Math.log( Math.tan( u / 2 ) ) + Math.cos( u ) )
    # x = a * (1 + Math.os(v)) * Math.sin(u);
    # y = a * (1 + Math.sin(v)) * Math.cos(u);
    # z = -a * 2 * Math.tan(u - Math.PI) * Math.sin(v);
    return [x, y, z]

  sphere_3d_points: () ->
    points = []
    @du = (Math.abs(@u_max - @u_min) / (@du_count))
    @dv = (Math.abs(@v_max - @v_min) / (@dv_count)) 
    u = @u_min
    v = @v_min
    u_max = @u_max - @du/2
    v_max = @v_max + @dv/2

    while u < u_max
      while v < v_max
        v += @dv
        points.push( this.point_equation(u, v) )
      u += @du
      v = @v_min
    return points
  
  # Вся твоя ошибка заключалась в том что ты дебил блять!
  # Ты делаешь диференс углов, получаешь нормальный результат, но не поварачивается!
  # А всё потому что не надо всё время заново создавать точки, а работать с имеющимися!!!
  sphere_screen_points: () ->
    points = this.sphere_3d_points()
    screen_points = []

    for point in points
      to_p = new Point( point[0], point[1], point[2], @x_angle, @y_angle, @z_angle )
      to_p.multiplicate(@result_matr)
      to_p = to_p.get_screen_projection()
      @to_newel[to_p] = [ point[0], point[1], point[2] ]
      screen_points.push( to_p )
    return screen_points

  sphere_segments: () ->
    points = this.sphere_screen_points()
    segments = []
    for i in [0...points.length - @dv_count - 1]
      segments.push( [ points[i],  points[i + @dv_count + 1], points[i + @dv_count], points[i], points[i + 1] ])

    return segments

  calculate_flat_abc: (segment) ->
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

      a += (first_surf_point[1] - second_surf_point[1]) * (first_surf_point[2] + second_surf_point[2])
      b += (first_surf_point[2] - second_surf_point[2]) * (first_surf_point[0] + second_surf_point[0])
      c += (first_surf_point[0] - second_surf_point[0]) * (first_surf_point[1] + second_surf_point[1])
    return [a, b, c]

  fill_segment: (segment) ->
    abc = this.calculate_flat_abc( segment )
    a = abc[0]
    b = abc[1]
    c = abc[2]
    cos_s_n = -c / Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) + Math.pow(c , 2) )
    color_in = [0, 0, 0]
    color_out = [0, 0, 0]
    color = 0
    if cos_s_n < 0
      color_in[0] = Math.round( @color_in[0]*(-cos_s_n))
      color_in[1] = Math.round(@color_in[1]*(-cos_s_n))
      color_in[2] = Math.round(@color_in[2]*(-cos_s_n))
      color = "rgb(#{color_in[0]},#{color_in[1]},#{color_in[2]})"
    else if cos_s_n > 0
      color_out[0] = Math.round(@color_out[0]*cos_s_n)
      color_out[1] = Math.round(@color_out[1]*cos_s_n)
      color_out[2] = Math.round(@color_out[2]*cos_s_n)
      color = "rgb(#{color_out[0]},#{color_out[1]},#{color_out[2]})"

    if color != 0
      jc.line([segment[0], segment[4], segment[1], segment[2], segment[0]], color, true )

  draw_axises: () ->
    jc.line([[0,0],[100,0]])
    jc.line([[0,0],[0,100]])
    jc.text("x", 101, 10)
    jc.text("y", 7, 101)

  draw: () ->
    jc.clear("canvas")
    jc.start('canvas', true)
    segments = this.sphere_segments()
    if @flat
      for segment in segments
        this.fill_segment(segment)
    else
      for segment in segments
        jc.line(segment)
    # Координатные оси
    this.draw_axises()


#------------------- Конец описания классов ---------------------------------------

$ ->
  # Иниициализация начальных значений поверхности
  u_min = 0.0
  v_min = 0.0
  u_max = Math.PI/2
  v_max = 2*Math.PI
  sp = new PseudoSphere( u_min, v_min, u_max, v_max )
  sp.draw()

  a_val = -3
  u_val = 100
  v_val = 10
  col_val = 121
  u_min = 0
  u_max = 200
  @angle_min = 0
  @angle_max = 360
  @angle_val = 0
  @d_max = 50
  @d_min = 1
  @d_step = 1
  @min_col = 0
  @max_col = 255
  @d_val = 20

  # Слайдеры для управления вращением объекта
  $('#angle_x').slider
    min: @angle_min
    max: @angle_max
    value: @angle_val
    slide: (event, ui) ->
      $('#angle_x p').html("X: #{ui.value} &isin; [-90...90]")
      sp.set_camera_x_angle( ui.value )
      sp.draw()

  $('#angle_y').slider
    min: @angle_min
    max: @angle_max
    value: @angle_val
    slide: (event, ui) ->
      $('#angle_y p').html("Y: #{ui.value} &isin; [-90...90]")
      sp.set_camera_y_angle( ui.value )
      sp.draw()

  $('#angle_z').slider
    min: @angle_min
    max: @angle_max
    value: @angle_val
    slide: (event, ui) ->
      $('#angle_z p').html("Z: #{ui.value} &isin; [-90...90]")
      sp.set_camera_z_angle( ui.value )
      sp.draw()

   # ---------------------------------------------------


   # Слайдеры для управления параметрами поверхности
   $('#u').slider
    min: u_min
    max: u_max
    value: u_val
    slide: (event, ui) ->
      $('#u p').html("U: #{ui.value} &isin; [0...200]")
      sp.set_u(ui.value)
      sp.draw()

  $('#v').slider
    min: u_min
    max: u_max
    value: v_val
    slide: (event, ui) ->
      $('#v p').html("V: #{ui.value} &isin; [0...200]")
      sp.set_v(ui.value)
      sp.draw()

  $('#step_u').slider
    min: @d_min
    max: @d_max
    step: @d_step
    value: @d_val
    slide: (event, ui) ->
      $('#step_u p').html("DU: #{ui.value} &isin; [0...50]")
      sp.set_du_count(ui.value)
      sp.draw()

  $('#step_v').slider
    min: @d_min
    max: @d_max
    step: @d_step
    value: @d_val
    slide: (event, ui) ->
      $('#step_v p').html("DV: #{ui.value} &isin; [0...50]")
      sp.set_dv_count(ui.value)
      sp.draw()

  $('#a').slider
    min: -10
    max: 10
    step: @d_step
    value: a_val
    slide: (event, ui) ->
      $('#a p').html("A: #{ui.value} &isin; [-10...10]")
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


  # ----------------------------------------------------


  # Слайдеры для управления цветом
  $('.in_color #r').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.in_color #r p').html("r: #{ui.value} 	&isin; [0...255]")
      sp.set_in_color([ui.value,  $('.in_color #g').slider("value"), $('.in_color #b').slider("value") ])
      color = "rgb(" + ui.value + "," + $('.in_color #g').slider("value") + "," + $('.in_color #b').slider("value") + ")"
      $('#in_color_show').css('background-color', color)
      sp.draw()

  $('.in_color #g').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.in_color #g p').html("g: #{ui.value} &isin; [0...255]")
      sp.set_in_color([$('.in_color #r').slider("value"),  ui.value, $('.in_color #b').slider("value") ])
      color = "rgb(" + $('.in_color #r').slider("value") + "," + ui.value + "," + $('.in_color #b').slider("value") + ")"
      $('#in_color_show').css('background-color', color)
      sp.draw()

  $('.in_color #b').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.in_color #b p').html("b: #{ui.value} &isin; [0...255]")
      sp.set_in_color([$('.in_color #r').slider("value"),  $('.in_color #g').slider("value"), ui.value ])
      color = "rgb(" + $('.in_color #r').slider("value") + "," + $('.in_color #g').slider("value") + "," + ui.value + ")"
      $('#in_color_show').css('background-color', color)
      sp.draw()

  $('.out_color #r').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.out_color #r p').html("r: #{ui.value} &isin; [0...255]")
      sp.set_out_color([ui.value,  $('.out_color #g').slider("value"), $('.out_color #b').slider("value") ])
      color = "rgb(" + ui.value + "," + $('.out_color #g').slider("value") + "," + $('.out_color #b').slider("value") + ")"
      $('#out_color_show').css('background-color', color)
      sp.draw()

  $('.out_color #g').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.out_color #g p').html("g: #{ui.value} &isin; [0...255]")
      sp.set_out_color([$('.out_color #r').slider("value"),  ui.value, $('.out_color #b').slider("value") ])
      color = "rgb(" + $('.out_color #r').slider("value") + "," + ui.value + "," + $('.out_color #b').slider("value") + ")"
      $('#out_color_show').css('background-color', color)
      sp.draw()

  $('.out_color #b').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.out_color #b p').html("b: #{ui.value} &isin; [0...255]")
      sp.set_out_color([$('.out_color #r').slider("value"),  $('.out_color #g').slider("value"), ui.value ])
      color = "rgb(" + $('.out_color #r').slider("value") + "," + $('.out_color #g').slider("value") + "," +  ui.value + ")"
      $('#out_color_show').css('background-color', color)
      sp.draw()

