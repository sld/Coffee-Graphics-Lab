# Math - принимают на вход Vector
Math.vector_length = (a) ->
  return Math.sqrt( Math.pow(a.e(1), 2) + Math.pow(a.e(2), 2) + Math.pow(a.e(3), 2) )

Math.cos_ab = (a, b) ->
  return ( a.e(1)*b.e(1) + a.e(2)*b.e(2) + a.e(3)*b.e(3) ) / (Math.vector_length(a) * Math.vector_length(b) + 0.00001)
