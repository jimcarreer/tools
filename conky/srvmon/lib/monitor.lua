require 'cairo'
require 'lib.util'
require 'lib.point'

MonitorElement = {
  topLeft = Point(0, 0),
  display = nil,
  borderWidth = 2,
  width = 120,
  height = 100,
}
MonitorElement = class(MonitorElement)


function MonitorElement.new(topLeft)
  local self = setmetatable({}, MonitorElement)
  self.topLeft = topLeft or Point(0, 0)
  return self
end

function MonitorElement:render()
  cairo_set_line_width(self.display, self.borderWidth)
  cairo_rectangle(self.display, self.topLeft.x, self.topLeft.y, self.width, self.height)
  cairo_move_to(self.display, self.topLeft.x + 100, self.topLeft.y)
end
