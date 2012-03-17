
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
  $('.diffuse_color').draggable()
  $('.point_color').draggable()

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
      $('.in_color #r p').html("r: #{ui.value}  &isin; [0...255]")
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


#---------------------------------
# Слайдеры для управления цветом источника света
  col_val = 255
  $('.diffuse_color #r').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.in_color #r p').html("r: #{ui.value}  &isin; [0...255]")
      sp.set_diffuse_color([ui.value,  $('.diffuse_color #g').slider("value"), $('.diffuse_color #b').slider("value") ])
      color = "rgb(" + ui.value + "," + $('.diffuse_color #g').slider("value") + "," + $('.diffuse_color #b').slider("value") + ")"
      $('#diffuse_color_show').css('background-color', color)
      sp.draw()

  $('.diffuse_color #g').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.diffuse_color #g p').html("g: #{ui.value} &isin; [0...255]")
      sp.set_diffuse_color([$('.diffuse_color #r').slider("value"),  ui.value, $('.diffuse_color #b').slider("value") ])
      color = "rgb(" + $('.diffuse_color #r').slider("value") + "," + ui.value + "," + $('.diffuse_color #b').slider("value") + ")"
      $('#diffuse_color_show').css('background-color', color)
      sp.draw()

  $('.diffuse_color #b').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.diffuse_color #b p').html("b: #{ui.value} &isin; [0...255]")
      sp.set_diffuse_color([$('.diffuse_color #r').slider("value"),  $('.diffuse_color #g').slider("value"), ui.value ])
      color = "rgb(" + $('.diffuse_color #r').slider("value") + "," + $('.diffuse_color #g').slider("value") + "," + ui.value + ")"
      $('#diffuse_color_show').css('background-color', color)
      sp.draw()

  $('.point_color #r').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.point_color #r p').html("r: #{ui.value} &isin; [0...255]")
      sp.set_point_color([ui.value,  $('.point_color #g').slider("value"), $('.point_color #b').slider("value") ])
      color = "rgb(" + ui.value + "," + $('.point_color #g').slider("value") + "," + $('.point_color #b').slider("value") + ")"
      $('#point_color_show').css('background-color', color)
      sp.draw()

  $('.point_color #g').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.point_color #g p').html("g: #{ui.value} &isin; [0...255]")
      sp.set_point_color([$('.point_color #r').slider("value"),  ui.value, $('.point_color #b').slider("value") ])
      color = "rgb(" + $('.point_color #r').slider("value") + "," + ui.value + "," + $('.point_color #b').slider("value") + ")"
      $('#point_color_show').css('background-color', color)
      sp.draw()

  $('.point_color #b').slider
    min: @min_col
    max: @max_col
    step: 1
    value: col_val
    slide: (event, ui) ->
      $('.point_color #b p').html("b: #{ui.value} &isin; [0...255]")
      sp.set_point_color([$('.point_color #r').slider("value"),  $('.point_color #g').slider("value"), ui.value ])
      color = "rgb(" + $('.point_color #r').slider("value") + "," + $('.point_color #g').slider("value") + "," +  ui.value + ")"
      $('#point_color_show').css('background-color', color)
      sp.draw()
