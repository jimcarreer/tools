require 'lib.point'

MonitorElement = {
  topLeft = Point:new(nil, 0, 0),
  display = nil,
  font = DEFAULT_FONT,
}

function MonitorElement:new(o, display, topLeft)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.topLeft = topLeft or Point:new(nil, 0, 0)
  self.display = display
  return o
end

function MonitorElement:updates()
  return tonumber(conky_parse('${updates}'))
end

function MonitorElement:render()
  cairo_move_to(self.display, self.topLeft.x, self.topLeft.y)
  cairo_show_text(self.display, self.topLeft:str()..':'..self:updates())
end
