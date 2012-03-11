# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class Point
  constructor: (x, y, z) ->
    @x = x
    @y = y
    @z = z

    this.set_default_values()
  
  set_default_values: ()->
    # Для Move Matrix
    @xSize = 2800
    @ySize = 1900
    @central_project = false

  set_angle: (a, b, c) ->
    @x_angle = a
    @y_angle = b
    @z_angle = c

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


  get_x: () ->
    return @x
  
  get_y: () ->
    return @y

  get_z: () ->
    return @z

  get_matrixes: () ->
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
    if alpha >= 0 && alpha <= Math.PI/2
      return intensity * alpha
    else
      return 0

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
    return @ka * this.ambient( a_i ) + @kd * this.diffuse(normale_vector, d_i) + @kr * this.reflect(normale_vector, reflection_i) 

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


# Math - принимают на вход Vector
Math.vector_length = (a) ->
  return Math.sqrt( Math.pow(a.e(1), 2) + Math.pow(a.e(2), 2) + Math.pow(a.e(3), 2) )

Math.cos_ab = (a, b) ->
  return ( a.e(1)*b.e(1) + a.e(2)*b.e(2) + a.e(3)*b.e(3) ) / (Math.vector_length(a) * Math.vector_length(b))



class Surface
  constructor: (u_min, v_min, u_max, v_max) ->
    @u_max = u_max
    @v_max = v_max
    @u_min = 0
    @v_min = 0

    @x_angle = 0*Math.PI/180
    @y_angle = 0*Math.PI/180
    @z_angle = 0*Math.PI/180

    @surface_parameter = 1
    @dv_count = 11
    @du_count = 20

    # Хэш, где хранится отображение экранных координат в пространственные
    @screen_to_object_coordinates_hash = new Array()
    @flat = false

    @color_out = [123, 200, 20]
    @color_in = [255,255,22]

    @prev_x_angle =  @x_angle
    @prev_y_angle =  @y_angle
    @prev_z_angle =  @z_angle

    @flat_with_zbuffer = false

    # Результирующая матрица для поворота
    @result_matr = Matrix.I(4)

    # Координаты источника света
    @light = new Light(100, 100, 100)


  
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
    @prev_x_angle = val*radian
    this.rotate_result_matr('x')

  set_camera_y_angle: ( val ) ->
    radian = Math.PI / 180
    @y_angle = val*radian - @prev_y_angle
    @prev_y_angle = val*radian
    this.rotate_result_matr('y')

  set_camera_z_angle: ( val ) ->
    radian = Math.PI / 180
    @z_angle = val*radian - @prev_z_angle
    @prev_z_angle = val*radian
    this.rotate_result_matr('z')

  set_du_count: ( val ) ->
    @du_count = val

  set_dv_count: ( val ) ->
    @dv_count = val

  set_u: ( val ) ->
    @u_max = val * Math.PI / 180

  set_v: ( val ) ->
    @v_max = val * Math.PI / 180

  set_flat: ( val ) ->
    @flat = val
    @flat_with_zbuffer = false

  set_flat_with_zbuffer: ( val ) ->
    @flat_with_zbuffer = val
    @flat = false

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

  set_light_coords: (x, y, z) ->
    @light.set_x_coord(x)
    @light.set_y_coord(y)
    @light.set_z_coord(z)

  set_light_koeff: (ka, kd, kr) ->
    @light.set_ka(ka)
    @light.set_kd(kd)
    @light.set_kr(kr)

  # NOTE: Ещё раз говорю посмотри как получить доступ к объекту наподобие attr_accessor
  set_light_refl_n: ( val ) ->
    @light.set_n( val )

  point_equation: ( u, v ) ->
    a = @surface_parameter * 1000
    x = a * Math.sin( u ) * Math.cos( v ) 
    y = a * Math.sin( u ) * Math.sin( v ) 
    z = a * ( Math.log( Math.tan( u / 2 ) ) + Math.cos( u ) )
    return [x, y, z]

  surface_3d_points: () ->
    points = []
    @du = ((@u_max - @u_min) / (@du_count))
    @dv = ((@v_max - @v_min) / (@dv_count)) 
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

  surface_screen_points: () ->
    points = this.surface_3d_points()
    screen_points = []
    for point in points
      working_point = new Point( point[0], point[1], point[2])
      working_point.set_angle( @x_angle, @y_angle, @z_angle )
      working_point.multiplicate(@result_matr)
      to_p = working_point.get_screen_projection()
      @screen_to_object_coordinates_hash[to_p] = [ working_point.get_x(), working_point.get_y(), working_point.get_z() ]
      screen_points.push( to_p )

    return screen_points
  
  surface_segments: () ->
    points = this.surface_screen_points()
    segments = []

    for v_ind in [0...@du_count-1]
      for u_ind in [0...@dv_count]

        point_one = v_ind * @dv_count + v_ind + u_ind
        point_two = point_one + 1
        point_three = (v_ind + 1) * @dv_count + v_ind + 1 + u_ind
        point_four = point_three + 1

        poly_one = [points[point_one], points[point_two], points[point_three]]
        poly_two = [points[point_four], points[point_three], points[point_two]]

        segments.push( poly_one )
        segments.push( poly_two )
    return segments

  # Подсчёт координат вектора нормали для сегмента
  calculate_normale: (segment) ->
    a = 0.0
    b = 0.0
    c = 0.0
    j = 0
    for i in [0...segment.length ]
      if i == segment.length - 1
        j = 0
      else
        j = i + 1
      first_surf_point = @screen_to_object_coordinates_hash[ segment[i] ]
      second_surf_point = @screen_to_object_coordinates_hash[ segment[j] ]

      a += (first_surf_point[1] - second_surf_point[1]) * (first_surf_point[2] + second_surf_point[2])
      b += (first_surf_point[2] - second_surf_point[2]) * (first_surf_point[0] + second_surf_point[0])
      c += (first_surf_point[0] - second_surf_point[0]) * (first_surf_point[1] + second_surf_point[1])
    return [a, b, c]

  flat_filling: (segment, ctx) ->
    abc = this.calculate_normale( segment )
    a = abc[0]
    b = abc[1]
    c = abc[2]
    length_n = Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) + Math.pow(c , 2) )
    cos_s_n = -c / length_n
    color_in = [undefined, undefined, undefined]
    color_out = [undefined, undefined, undefined]
    color = ""
    if cos_s_n < 0
      color_in[0] = Math.round(@color_in[0]*(-cos_s_n))
      color_in[1] = Math.round(@color_in[1]*(-cos_s_n))
      color_in[2] = Math.round(@color_in[2]*(-cos_s_n))
      color = "rgb(#{color_in[0]},#{color_in[1]},#{color_in[2]})"
    else 
      color_out[0] = Math.round(@color_out[0]*cos_s_n)
      color_out[1] = Math.round(@color_out[1]*cos_s_n)
      color_out[2] = Math.round(@color_out[2]*cos_s_n)
      color = "rgb(#{color_out[0]},#{color_out[1]},#{color_out[2]})"

    if color != 0
      ctx.fillStyle = color; 
      ctx.beginPath()
      ctx.moveTo(segment[0][0], segment[0][1])
      ctx.lineTo(segment[1][0], segment[1][1])
      ctx.lineTo(segment[2][0], segment[2][1])
      ctx.fill()



  flat_filling_with_zbuffer: (segment, ctx, canvasData) ->
    abc = this.calculate_normale( segment )
    a = abc[0]
    b = abc[1]
    c = abc[2]
    length_n = Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) + Math.pow(c , 2) )
    cos_s_n = -c / length_n
    color_in = [undefined, undefined, undefined]
    color_out = [undefined, undefined, undefined]
    color_arr = []

    normale = Vector.create( abc )
    if cos_s_n < 0
      color_arr[0] = parseInt(@light.summary_intensity( 210, 5, 100, @color_in[0], normale ))
      color_arr[1] = parseInt(@light.summary_intensity( 210, 5, 100, @color_in[1], normale ))
      color_arr[2] = parseInt(@light.summary_intensity( 210, 5, 100, @color_in[2], normale ))
    else 
      color_arr[0] = parseInt(@light.summary_intensity( 210, 5, 100, @color_out[0], normale ))
      color_arr[1] = parseInt(@light.summary_intensity( 210, 5, 100, @color_out[1], normale ))
      color_arr[2] = parseInt(@light.summary_intensity( 210, 5, 100, @color_out[2], normale ))

    if color_arr != []
      pixels = this.rasterization(segment)
      for pxl in pixels
        x = pxl[0]
        y = pxl[1]
        if ( x >= 0 && y >= 0 && x < 600 && y < 600 )
          z = this.calculate_z( segment[0], a, b, c, x, y )
          if ( z > @zbuffer[x][y] )  
            @zbuffer[x][y] = z
            this.setPixel(canvasData, x, y, color_arr[0], color_arr[1], color_arr[2], 255)
  
  calculate_z: ( point, a, b, c, x, y ) ->
    surf_point = @screen_to_object_coordinates_hash[ point ]
    d = -(a*surf_point[0] + b*surf_point[1] + c*surf_point[2])
    ans = -(a * x + b * y + d  ) / c
    return ans

  ` 
  Array.prototype.swap = function (x,y) {
    var b = this[x];
    this[x] = this[y];
    this[y] = b;
    return this;
  }
  `
  rasterization: (segment) ->
    working_segment = [1, 2, 3]
    working_segment[0] = segment[0]
    working_segment[1] = segment[1]
    working_segment[2] = segment[2]
    
    a = working_segment[0]
    b = working_segment[1]
    c = working_segment[2]
    pixels = []

    # Сортируем вершины по y( 2 раза )
    if a[1] > b[1]
      working_segment.swap(0, 1)
    if a[1] > c[1]
      working_segment.swap(0, 2)
    if b[1] > c[1]
      working_segment.swap(1, 2)

    a = working_segment[0]
    b = working_segment[1]
    c = working_segment[2]

    if a[1] > b[1]
      working_segment.swap(0, 1)
    if a[1] > c[1]
      working_segment.swap(0, 2)
    if b[1] > c[1]
      working_segment.swap(1, 2)

    a = working_segment[0]
    b = working_segment[1]
    c = working_segment[2]

    x1 = parseInt(a[0])
    y1 = parseInt(a[1])
    x2 = parseInt(b[0])
    y2 = parseInt(b[1])
    x3 = parseInt(c[0])
    y3 = parseInt(c[1])

    dx13 = 0.0
    dx12 = 0.0
    dx23 = 0.0

    # Вычисляем приращения
    dy31 = y3 - y1
    if (dy31 != 0)
      dx13 = (x3 - x1) / (y3 - y1)
    dy21 = y2 - y1
    if (dy21 != 0)
      dx12 = (x2 - x1) / (y2 - y1)
    dy32 = y3 - y2
    if (dy32 != 0)
      dx23 = (x3 - x2) / (y3 - y2)
    
    wx1 = x1
    wx2 = wx1

    _dx13 = dx13

    if (dx13 > dx12)
      t = dx12
      dx12 = dx13
      dx13 = t    
    # Рисованеи верхнего треугольника
    `
    for(var i = parseInt(y1); i < y2; i++ )
    {
      for (var j = parseInt(wx1); j <= parseInt(wx2); j++ )
      {
        pixels.push( [j, i] );
      }
      wx1 += dx13;
      wx2 += dx12;
    }
    `
    
    if (y1 == y2)
      wx1 = x1
      wx2 = x2
    
    if Math.abs(y1 - y2) < 0.01
      wx1 = x1
      wx2 = x2

    if wx1 > wx2
      t = wx2
      wx2 = wx1
      wx1 = t 

    if (_dx13 < dx23)
      t = _dx13
      _dx13 = dx23
      dx23 = t 
    
    # Растеризация нижнего треугольника
    `
    for( var i = parseInt(y2); i <= y3; i++ )
    {
      for ( var j = parseInt(wx1); j <= parseInt(wx2); j++ )
      {
        pixels.push( [j, i] );
      }
      wx1 += _dx13;
      wx2 += dx23;
    }
    ` 
    return pixels
    
  #NOTE:::       Ставим свет!!!

  draw_axises: ( ctx ) ->
    ctx.beginPath()
    ctx.moveTo(0,0)
    ctx.lineTo(100,0)
    ctx.closePath()
    ctx.stroke()

    ctx.beginPath()
    ctx.moveTo(0,0)
    ctx.lineTo(0,100)
    ctx.closePath()
    ctx.stroke()

    ctx.fillText("x", 101, 10)
    ctx.fillText("y", 7, 101)

  setPixel: (imageData, x, y, r, g, b, a) ->
    index = (x + y * imageData.width) * 4;
    imageData.data[index+0] = r;
    imageData.data[index+1] = g;
    imageData.data[index+2] = b;
    imageData.data[index+3] = a;

  draw: () ->
    canvas = document.getElementById('canvas')
    ctx = canvas.getContext('2d')

    ctx.save()
    ctx.setTransform(1, 0, 0, 1, 0, 0)
    ctx.clearRect(0, 0, canvas.width, canvas.height)

    ctx.restore()

    segments = this.surface_segments()
    if @flat  
      canvasData = ctx.createImageData(canvas.width, canvas.height);
      for segment in segments 
        this.flat_filling(segment, ctx)
    else if @flat_with_zbuffer
      @zbuffer = new Array(canvas.width+1)
      `
      for(var i = 0; i<canvas.width+1; i++) 
        this.zbuffer[i] = new Array(canvas.height+1);
      `
      `
      for( var i = 0; i < canvas.width + 1; i++ )
        for( var j = 0; j < canvas.height + 1; j++ )
          this.zbuffer[i][j] = -77777777777777777777.0
      `
      canvasData = ctx.createImageData(canvas.width, canvas.height);
      for segment in segments 
        this.flat_filling_with_zbuffer(segment, ctx, canvasData)
      ctx.putImageData(canvasData, 0, 0)
    else
      for segment in segments
        ctx.beginPath()
        ctx.moveTo(segment[0][0], segment[0][1])
        ctx.lineTo(segment[1][0], segment[1][1])
        ctx.lineTo(segment[2][0], segment[2][1])
        ctx.closePath()
        ctx.stroke()

    this.draw_axises(ctx)


#------------------- Конец описания классов ---------------------------------------

$ ->
  # Иниициализация начальных значений поверхности
  u_min = 0.0
  v_min = 0.0
  u_max = 2*Math.PI/2
  v_max = 2*Math.PI
  sp = new Surface( u_min, v_min, u_max, v_max )
  sp.draw()

  a_val = 1
  u_val = 45
  v_val = 360
  col_val = 121
  radian = 180/Math.PI
  @angle_min = -90
  @angle_max = 90
  @angle_val = 0
  @d_max = 50
  @d_min = 1
  @d_step = 1
  @min_col = 0
  @max_col = 255
  @d_val = 20

  # Делаем элементы управления перетаскиваемыми
  $('.angle_sliders').draggable()
  $('.in_color').draggable()
  $('.out_color').draggable()
  $('.surface_parameters').draggable()
  $('.light_coords').draggable()
  $('.light_properties').draggable()

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
    min: u_min*radian
    max: u_max*radian
    value: u_val
    slide: (event, ui) ->
      $('#u p').html("U: #{ui.value} &isin; [0...200]")
      sp.set_u(ui.value)
      sp.draw()

  $('#v').slider
    min: v_min*radian
    max: v_max*radian
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
    min: 0
    max: 10
    step: @d_step
    value: a_val
    slide: (event, ui) ->
      $('#a p').html("A: #{ui.value} &isin; [0...10]")
      sp.set_surface_parameter(ui.value)
      sp.draw()

  $("input[name='filling']").change ->
    if ($("input[@name='filling']:checked").val() == 'frame')
      sp.set_flat(false)
      sp.draw()
    else if ($("input[@name='filling']:checked").val() == 'flat')
      sp.set_flat(true)
      sp.draw()
    else if ($("input[@name='filling']:checked").val() == 'flat_with_zbuffer')
      sp.set_flat_with_zbuffer(true)
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

  @light_min = -300
  @light_max = 300
  @light_coord_val = 100
  # NOTE: Посмотри как получить доступ к объекту в классе
  $('.light_coords #x').slider
    min: @light_min
    max: @light_max
    step: 1
    value: @light_coord_val
    slide: (event, ui) ->
      $('.light_coords #x p').html("X: #{ui.value} &isin; [-300...300]")
      sp.set_light_coords(ui.value,  $('.light_coords #y').slider("value"), $('.light_coords #z').slider("value") )
      sp.draw()

  $('.light_coords #y').slider
    min: @light_min
    max: @light_max
    step: 1
    value: @light_coord_val
    slide: (event, ui) ->
      $('.light_coords #y p').html("Y: #{ui.value} &isin; [-300...300]")
      sp.set_light_coords($('.light_coords #x').slider("value"), ui.value, $('.light_coords #z').slider("value") )
      sp.draw()

  $('.light_coords #z').slider
    min: @light_min
    max: @light_max
    step: 1
    value: @light_coord_val
    slide: (event, ui) ->
      $('.light_coords #z p').html("Z: #{ui.value} &isin; [-300...300]")
      sp.set_light_coords($('.light_coords #x').slider("value"), $('.light_coords #y').slider("value"), ui.value )
      sp.draw()

  @light_prop_min = 0
  @light_prop_max = 1
  @light_prop_val = 0.3
  $('.light_properties #ambient').slider
    min: @light_prop_min
    max: @light_prop_max
    step: 0.1
    value: @light_prop_val
    slide: (event, ui) ->
      $('.light_properties #ambient p').html("ka: #{ui.value} &isin; [0...1]")
      sp.set_light_koeff(ui.value,  $('.light_properties #diffuse').slider("value"), $('.light_properties #reflection').slider("value") )
      sp.draw()
    
  $('.light_properties #diffuse').slider
    min: @light_prop_min
    max: @light_prop_max
    step: 0.1
    value: @light_prop_val
    slide: (event, ui) ->
      $('.light_properties #diffuse p').html("kd: #{ui.value} &isin; [0...1]")
      sp.set_light_koeff($('.light_properties #ambient').slider("value"), ui.value, $('.light_properties #reflection').slider("value") )
      sp.draw()

  $('.light_properties #reflection').slider
    min: @light_prop_min
    max: @light_prop_max
    step: 0.1
    value: @light_prop_val
    slide: (event, ui) ->
      $('.light_properties #reflection p').html("kr: #{ui.value} &isin; [0...1]")
      sp.set_light_koeff($('.light_properties #ambient').slider("value"), $('.light_properties #diffuse').slider("value"), ui.value )
      sp.draw()

  $('.light_properties #n').slider
    min: 0
    max: 20
    step: 1
    value: 5
    slide: (event, ui) ->
      $('.light_properties #n p').html("n: #{ui.value} &isin; [0...1]")
      sp.set_light_refl_n( ui.value )
      sp.draw()


