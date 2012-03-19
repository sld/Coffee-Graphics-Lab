# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

#=require 'math'
#=require 'point'
#=require 'light'

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

    @ambient_col = [255, 255, 255]
    @diff_col = [255, 255, 255]

    @prev_x_angle =  @x_angle
    @prev_y_angle =  @y_angle
    @prev_z_angle =  @z_angle

    @flat_with_zbuffer = false

    # Результирующая матрица для поворота
    @result_matr = Matrix.I(4)

    # Координаты источника света
    @light = new Light(100, 100, 100)

    @guro = false
    @phong = false
    @point_segments = new Array()

  
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
    @guro = false
    @phong = false

  set_flat_with_zbuffer: ( val ) ->
    @flat_with_zbuffer = val
    @flat = false
    @guro =false
    @phong = false

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

  set_ambient_col: (col_arr) ->
    @ambient_col = col_arr

  set_diffuse_color: (col_arr) ->
    @diff_col = col_arr

  set_point_color: (col_arr) ->
    @ambient_col = col_arr

  set_guro: (val) ->
    @guro = val
    @flat_with_zbuffer = false
    @flat = false 
    @phong = false

  set_phong: (val) ->
    @phong = val
    @guro = false
    @flat_with_zbuffer = false
    @flat = false 

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
  
  insert_into_point_segments: ( point, poly) ->
    if @point_segments[point] && (not (poly in  @point_segments[point]))
      @point_segments[point].push( poly )
    else if !@point_segments[point]
      @point_segments[point] = [poly]

  surface_segments: () ->
    points = this.surface_screen_points()
    segments = []

    # Хэш вида { 3D_Точка -> [ Полигоны ]}

    for v_ind in [0...@du_count-1]
      for u_ind in [0...@dv_count]

        point_one = v_ind * @dv_count + v_ind + u_ind
        point_two = point_one + 1
        point_three = (v_ind + 1) * @dv_count + v_ind + 1 + u_ind
        point_four = point_three + 1

        poly_one = [points[point_one], points[point_two], points[point_three]]
        poly_two = [points[point_four], points[point_three], points[point_two]]

        point_one = @screen_to_object_coordinates_hash[points[point_one]]
        point_two = @screen_to_object_coordinates_hash[points[point_two]]
        point_three = @screen_to_object_coordinates_hash[points[point_three]]
        point_four = @screen_to_object_coordinates_hash[points[point_four]]

        this.insert_into_point_segments( point_one, poly_one )
        this.insert_into_point_segments( point_two, poly_one )
        this.insert_into_point_segments( point_three, poly_one )
        this.insert_into_point_segments( point_four, poly_two )
        this.insert_into_point_segments( point_three, poly_two )
        this.insert_into_point_segments( point_two, poly_two )

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
      if !first_surf_point
        first_surf_point = 0
      if !second_surf_point
        second_surf_point = 0

      a += (first_surf_point[1] - second_surf_point[1]) * (first_surf_point[2] + second_surf_point[2])
      b += (first_surf_point[2] - second_surf_point[2]) * (first_surf_point[0] + second_surf_point[0])
      c += (first_surf_point[0] - second_surf_point[0]) * (first_surf_point[1] + second_surf_point[1])
    return [a, b, c]

  calc_cos: (normale) ->
    a = normale[0]
    b = normale[1]
    c = normale[2]
    length_n = Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) + Math.pow(c , 2) )
    cos_s_n = -c / length_n
    return cos_s_n

  flat_filling: (segment, ctx) ->
    abc = this.calculate_normale( segment )

    #NOTE: Почему то сегментов больше чем 
    point_segments = @point_segments[@screen_to_object_coordinates_hash[segment[0]]]

    cos_s_n = this.calc_cos( abc )
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
    if !(this.isNaN_arr(abc))
      color_arr = this.calculate_light_intensity_with_cos( abc )
      if !(this.isNaN_arr(color_arr))
        @canvasData = canvasData
        if color_arr != []
          pixels = this.rasterization(segment)
          for pxl in pixels
            x = pxl[0]
            y = pxl[1]
            z = this.calculate_z( segment[0], abc[0], abc[1], abc[2], x, y )
            this.draw_zbuffer(x, y, z, color_arr )


  calculate_z: ( point, a, b, c, x, y ) ->
    surf_point = @screen_to_object_coordinates_hash[ point ]
    d = -(a*surf_point[0] + b*surf_point[1] + c*surf_point[2])
    ans = -(a * x + b * y + d  ) / c
    return parseInt(ans)

  calculate_point_normale: (segments) ->
    edge_normale = [0, 0, 0]
    segments ||= []
    for segment in segments
      normale = this.calculate_normale( segment )
      edge_normale[0] += normale[0] if normale[0] != NaN
      edge_normale[1] += normale[1] if normale[1] != NaN
      edge_normale[2] += normale[2] if normale[2] != NaN
    n = segments.length
    n = 1 if n == 0
    edge_normale[0] = ( edge_normale[0] / n)
    edge_normale[1] = ( edge_normale[1] / n)
    edge_normale[2] = ( edge_normale[2] / n)
    return edge_normale

  calculate_light_intensity: (color, normale) ->
    color_arr = [0, 0, 0]
    color_arr[0] = parseInt(@light.summary_intensity( @ambient_col[0], @diff_col[0], @diff_col[0], color[0], normale ))
    color_arr[1] = parseInt(@light.summary_intensity( @ambient_col[1], @diff_col[1], @diff_col[1], color[1], normale ))
    color_arr[2] = parseInt(@light.summary_intensity( @ambient_col[2], @diff_col[2], @diff_col[2], color[2], normale ))
    return color_arr

  calculate_light_intensity_with_cos: ( normale ) ->
    cos_s_n = this.calc_cos( normale )
    normale = Vector.create( normale )
    color_arr = []
    if cos_s_n < 0
      color_arr = this.calculate_light_intensity( @color_in, normale )
    else 
      color_arr = this.calculate_light_intensity( @color_out, normale )
    return color_arr

  guro_shading: (segment, ctx, canvasData) ->

    segment = this.sort_by_y(segment)
    segment = this.sort_by_y(segment)

    a = @screen_to_object_coordinates_hash[segment[0]]
    b = @screen_to_object_coordinates_hash[segment[1]]
    c = @screen_to_object_coordinates_hash[segment[2]]
    a_normale =  this.calculate_point_normale( @point_segments[a] ) 
    a_col = this.calculate_light_intensity_with_cos( a_normale )
    b_normale =  this.calculate_point_normale( @point_segments[b] )
    b_col = this.calculate_light_intensity_with_cos( b_normale )
    c_normale = this.calculate_point_normale( @point_segments[c] ) 
    c_col = this.calculate_light_intensity_with_cos( c_normale )
    
    x1 = 0
    x2 = 0
    z1 = 0
    z2 = 0
    col1 = new Array()
    col2 = new Array()
    @canvasData = canvasData
    if !(this.isNaN_arr(a_col) || this.isNaN_arr(b_col) || this.isNaN_arr(c_col))
      aa = parseInt(a[1])
      cc = parseInt(c[1])
      for scany in [aa..cc]
        x1 = a[0] + (scany - a[1])*(c[0] - a[0]) / (c[1] - a[1])
        z1 = a[2] + (scany - a[1])*(c[2] - a[2]) / (c[1] - a[1])
        col1[0] = a_col[0] + (scany - a[1]) * (c_col[0] - a_col[0]) / (c[1] - a[1])
        col1[1] = a_col[1] + (scany - a[1]) * (c_col[1] - a_col[1]) / (c[1] - a[1])
        col1[2] = a_col[2] + (scany - a[1]) * (c_col[2] - a_col[2]) / (c[1] - a[1])
        if (scany < b[1])
          col2[0] = a_col[0] + (scany - a[1]) * (b_col[0] - a_col[0]) / (b[1] - a[1])
          col2[1] = a_col[1] + (scany - a[1]) * (b_col[1] - a_col[1]) / (b[1] - a[1])
          col2[2] = a_col[2] + (scany - a[1]) * (b_col[2] - a_col[2]) / (b[1] - a[1])
          x2 = a[0] + (scany - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
          z2 = a[2] + (scany - a[1]) * (b[2] - a[2]) / (b[1] - a[1])
        else
          if( c[1] == b[1] )
            col2[0]  = b_col[0]
            col2[1]  = b_col[1]
            col2[2]  = b_col[2]
            x2 = b[0]
            z2 = b[2]
          else
            col2[0] = b_col[0] + (scany - b[1]) * (c_col[0] - b_col[0]) / (c[1] - b[1])
            col2[1] = b_col[1] + (scany - b[1]) * (c_col[1] - b_col[1]) / (c[1] - b[1])
            col2[2] = b_col[2] + (scany - b[1]) * (c_col[2] - b_col[2]) / (c[1] - b[1])
            x2 = b[0] + (scany - b[1]) * (c[0] - b[0]) / (c[1] - b[1])
            z2 = b[2] + (scany - b[1]) * (c[2] - b[2]) / (c[1] - b[1])
        this.linear_interpolation_color( col1, col2, x1, x2, z1, z2, scany)

  phong_shading: (segment, ctx, canvasData) ->

    segment = this.sort_by_y(segment)
    segment = this.sort_by_y(segment)

    segment_normale = this.calculate_normale(segment)
    @segment_cos = this.calc_cos(segment_normale)

    a = @screen_to_object_coordinates_hash[segment[0]]
    b = @screen_to_object_coordinates_hash[segment[1]]
    c = @screen_to_object_coordinates_hash[segment[2]]
    a_normale =  this.calculate_point_normale( @point_segments[a] ) 
    b_normale =  this.calculate_point_normale( @point_segments[b] )
    c_normale = this.calculate_point_normale( @point_segments[c] ) 

    
    x1 = 0
    x2 = 0
    z1 = 0
    z2 = 0
    @canvasData = canvasData
    norm = new Array()
    norm_pre = new Array()

    if !(this.isNaN_arr(a_normale) || this.isNaN_arr(b_normale) || this.isNaN_arr(c_normale))
      a_normale =  Vector.create( a_normale )
      b_normale =  Vector.create( b_normale )
      c_normale =  Vector.create( c_normale )

      aa = parseInt(a[1])
      cc = parseInt(c[1])
      for scany in [aa..cc]
        # alert([c[1], a[1]])
        x1 = a[0] + (scany - a[1])*(c[0] - a[0]) / (c[1] - a[1])
        z1 = a[2] + (scany - a[1])*(c[2] - a[2]) / (c[1] - a[1])
        norm_pre = (c_normale.subtract(a_normale)).x( (scany - a[1]) / (c[1] - a[1])) 
        norm_pre = a_normale.add( norm_pre )
        if (scany < b[1])
          norm = (b_normale.subtract(a_normale)).x( (scany - a[1]) / (b[1] - a[1]) )
          norm = a_normale.add( norm  )
          x2 = a[0] + (scany - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
          z2 = a[2] + (scany - a[1]) * (b[2] - a[2]) / (b[1] - a[1])
        else
          if( c[1] == b[1] )
            norm = b_normale
            x2 = b[0]
            z2 = b[2]
          else
            norm = (c_normale.subtract(b_normale)).x( (scany - a[1]) / (c[1] - b[1]))
            norm = a_normale.add( norm )
            x2 = b[0] + (scany - b[1]) * (c[0] - b[0]) / (c[1] - b[1])
            z2 = b[2] + (scany - b[1]) * (c[2] - b[2]) / (c[1] - b[1])
        # console.log(inspect_norm1, inspect_norm2)
        this.linear_interpolation_normale( norm_pre, norm, x1, x2, z1, z2, scany)
      
      
  isNaN_arr: (arr) ->
    return true if isNaN(arr[0]) || isNaN(arr[1]) || isNaN(arr[2])
    return false

  arrToInt: (arr) ->
    intarr = [0,0,0]
    intarr[0] = parseInt arr[0]
    intarr[1] = parseInt arr[1]
    intarr[2] = parseInt arr[2]
    return intarr


  linear_interpolation_normale: ( norm1, norm2, x1, x2, z1, z2, cury ) ->
    color = [0,0,0]
        
    x1 = parseInt(x1)
    x2 = parseInt(x2)
    dx = x2 - x1
    for i in [x1..x2]
      nrm = norm2.subtract(norm1)
      nrm = nrm.x( (i-x1)/dx )
      nrm = norm1.add(nrm)
      norm = nrm
      norm_arr = [ norm.e(1), norm.e(2), norm.e(3) ]
      color = this.calculate_light_intensity_with_cos( norm_arr )
      z = z1 + (i - x1)*(z2 - z1) / dx
      
      z = parseInt(z)
      y = parseInt(cury/10)  + 190
      x = parseInt(i/10)     + 280
      # if !(this.isNaN_arr(color))
      this.draw_zbuffer(x, y, z, color)

  linear_interpolation_color: ( col1, col2, x1, x2, z1, z2, cury ) ->
    color = [0,0,0]
    
    x1 = parseInt(x1)
    x2 = parseInt(x2)

    dx = x2 - x1
    for i in [x1..x2]
      color[0] = col1[0] + (i - x1)*(col2[0] - col1[0]) / dx
      color[1] = col1[1] + (i - x1)*(col2[1] - col1[1]) / dx
      color[2] = col1[2] + (i - x1)*(col2[2] - col1[2]) / dx
      z = z1 + (i - x1)*(z2 - z1) / (x2 - x1)
      
      z = parseInt(z)
      y = parseInt(cury/10)  + 190
      x = parseInt(i/10)     + 280
      this.draw_zbuffer(x, y, z, color)

  draw_zbuffer: (x, y, z, color) ->
    if ( x >= 0 && y >= 0 && x < 600 && y < 600 )
      if ( z > @zbuffer[x][y] )  
        @zbuffer[x][y] = z
        this.setPixel(@canvasData, x, y, color[0], color[1], color[2], 255)

  ` 
  Array.prototype.swap = function (x,y) {
    var b = this[x];
    this[x] = this[y];
    this[y] = b;
    return this;
  }
  `

  sort_by_y: (segment) ->
    working_segment = new Array()
    working_segment[0] = segment[0]
    working_segment[1] = segment[1]
    working_segment[2] = segment[2]
    a = working_segment[0]
    b = working_segment[1]
    c = working_segment[2]
    if a[1] > b[1]
      working_segment.swap(0, 1)
    if a[1] > c[1]
      working_segment.swap(0, 2)
    if b[1] > c[1]
      working_segment.swap(1, 2)

    return working_segment

  rasterization: (segment) ->
    pixels = []
    working_segment = []
    working_segment = this.sort_by_y( segment )
    working_segment = this.sort_by_y( working_segment )

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
    else if @guro
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
        this.guro_shading(segment, ctx, canvasData)
      ctx.putImageData(canvasData, 0, 0)

    else if @phong
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
        this.phong_shading(segment, ctx, canvasData)
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

window.Surface = Surface


#TODO:  ##################3
# подсчет нормали в вершинах

#------------------- Конец описания классов ---------------------------------------

#=require 'interface'