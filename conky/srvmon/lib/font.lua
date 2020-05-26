require 'cairo'
require 'lib.util'

Font = {
  name = 'Sans',
  slant = CAIRO_FONT_SLANT_NORMAL,
  weight = CAIRO_FONT_WEIGHT_NORMAL,
  size = 10.0,
  color = 0x000000,
  alpha = 1.0,
}
Font = class(Font)

function Font.new(name, size, color, weight, slant)
  local self = setmetatable({}, Font)
  self.name = name or Font.name
  self.slant = slant or Font.slant
  self.weight = slant or Font.weight
  self.size = size or Font.size
  self.color = color or Font.color
  return self
end

function Font:use()
  cairo_select_font_face(self.display, self.name, self.slant, self.weight)
  cairo_set_font_size(self.display, self.size)
  local c = self.color & 0x000000000FFFFFF
  local a = self.alpha
  if a > 1.0 then a = 1.0 end
  if a < 0.0 then a = 0.0 end
  cairo_set_source_rgb(
    self.display,
    ((c & 0xFF0000) >> 16)/255.0,
    ((c & 0x00FF00) >> 08)/255.0,
    ((c & 0x0000FF) >> 00)/255.0,
    a
  )
end
