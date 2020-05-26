require 'cairo'
require 'lib.util'

Color = {
  red= 1.0,
  green = 1.0,
  blue = 1.0,
  alpha = 1.0,
}
Color = class(Color)

function Color.new(red, green, blue, alpha)
  local self = setmetatable({}, Color)
  self.red = red
  self.green = green
  self.blue = blue
  self.alpha = alpha
  return self
end

function Color:use()
  cairo_set_source_rgba(
    self.display,
    self.red,
    self.green,
    self.blue,
    self.alpha
  )
end


Font = {
  name = 'Sans',
  slant = CAIRO_FONT_SLANT_NORMAL,
  weight = CAIRO_FONT_WEIGHT_NORMAL,
  size = 10.0,
  color = Color(1.0, 1.0, 1.0, 1.0),
}
Font = class(Font)

function Font.new(name, size, color, weight, slant)
  local self = setmetatable({}, Font)
  self.name = name or Font.name
  self.slant = slant or Font.slant
  self.weight = slant or Font.weight
  self.size = size or Font.size
  self.color = color or Color(1.0, 1.0, 1.0, 1.0)
  return self
end

function Font:use()
  cairo_select_font_face(self.display, self.name, self.slant, self.weight)
  cairo_set_font_size(self.display, self.size)
  self.color:use()
end
