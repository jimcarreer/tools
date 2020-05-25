Point = {
  x = 0,
  y = 0,
}

function Point:new(o, x, y)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.x = x
  self.y = y
  return o
end

function Point:str()
  return self.x..','..self.y
end
