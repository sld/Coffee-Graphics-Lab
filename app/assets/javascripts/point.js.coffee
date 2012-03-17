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


window.Point = Point
