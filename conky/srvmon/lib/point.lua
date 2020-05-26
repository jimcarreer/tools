require 'lib.util'

Point = {x = 0, y = 0}
Point = class(Point)

function Point.new(x, y)
  local self = setmetatable({}, Point)
  self.x = x
  self.y = y
  return self
end

function Point:str()
  return self.x..','..self.y
end
