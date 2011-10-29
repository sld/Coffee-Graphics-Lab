# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
class Point
  constructor: (x, y, z) ->
    @x = x
    @y = y
    @z = z

    @a = 1000
    @b = 1000
    @c = 1000

    @xSize = 2000
    @ySize = 1000
    @central_project = false

  sin_A: (a, b, c) ->
    if (a == 0 && b == 0)
      return 0
    return a/Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) )

  sin_B: (a, b, c) ->
    if (a==0 && b==0 && c==0)
      return 0
    return Math.sqrt(Math.pow(a, 2) + Math.pow(b, 2) ) / Math.sqrt( Math.pow(b, 2) + Math.pow(c, 2) + Math.pow(a, 2) )

  cos_A: (a, b, c) ->
    if (a==0 && b==0)
      return 1
    return b/Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) )

  cos_B: (a, b, c) ->
    if (a==0 && b==0 && c==0)
      return 1
    return c / Math.sqrt( Math.pow(a, 2) + Math.pow(b, 2) + Math.pow(c, 2) )

  calculate_sin_cos: () ->
    @sin_a = this.sin_A(@a, @b, @c)
    @cos_a = this.cos_A(@a, @b, @c)
    @sin_b = this.sin_B(@a, @b, @c)
    @cos_b = this.cos_B(@a, @b, @c)

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

    @move_xy   = Matrix.create([ [1,0,0,0],
                         [0,1,0,0],
                         [0,0,1,0],
                         [@xSize, @ySize,0,1] ])

    @project_xy = $M([ [1,0,0,0],
                          [0,1,0,0],
                          [0,0,0,0],
                          [0,0,0,1] ])

    dist = Math.sqrt(Math.pow(@a, 2) + Math.pow(@b, 2) + Math.pow(@c, 2))

    @central_pr =      $M([ [1,0,0,0],
                         [0,1,0,0],
                         [0,0,1,-1/dist],
                         [0,0,0,1] ])


  get_screen_projection: () ->
    this.calculate_sin_cos()
    this.get_matrixes()
    point = $M([[@x, @y, @z, 1]])
    rotate     = @rotate_z.x(@rotate_x)

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

    return [sx, sy]

class PseudoSphere
  constructor: (u_min, v_min, u_max, v_max) ->
    @u_max = u_max
    @v_max = v_max
    @u_min = u_min
    @v_min = v_min

  point_equation: ( u, v ) ->
    a = 1
    x = a * Math.sin( u ) * Math.cos( v )*1000
    y = a * Math.sin( u ) * Math.sin( v )*1000
    z = a * ( Math.log( Math.tan( u / 2 ) ) + Math.cos( u ) )*1000
    if z == -Infinity
      z = 0
    return [x, y, z]

  sphere_3d_points: () ->
    points = []
    u_min = @u_min
    v_min = @v_min
    u_max = @u_max
    v_max = @v_max
    while u_min < u_max
      while v_min < v_max
        points.push( this.point_equation(u_min, v_min) )
        v_min += 0.1
      u_min += 0.1
      v_min = @v_min
    return points

  draw: () ->
    points = this.sphere_3d_points()
    screen_points = []
    for point in points
      to_p = new Point( point[0], point[1], point[2] )
      screen_points.push( to_p.get_screen_projection() )
    for point in screen_points
      jc.circle( point[0]/10, point[1]/10, 0.1 )

$ ->
  u_min = 0.0
  v_min = 0.0
  u_max = Math.PI/2
  v_max = 2*Math.PI

  jc.clear("canvas")
  jc.start("canvas")
  sp = new PseudoSphere( u_min, v_min, u_max, v_max )
  sp.draw()
  jc.start("canvas")

