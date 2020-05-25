
require 'cairo'
require 'lib.point'
require 'lib.monitor'

DEFAULT_FONT = {
  name = 'UbuntuMono-Regular',
  size = 32.0,
  slant = CAIRO_FONT_SLANT_NORMAL,
  weight = CAIRO_FONT_WEIGHT_BOLD
}


function util_set_cario_font(cr, font)
  cairo_select_font_face(cr, font['name'], font['slant'], font['weight'])
  cairo_set_font_size(cr, font['size'])
end

function conky_main()
  if conky_window == nil then
      return
  end

  local cs = cairo_xlib_surface_create(
    conky_window.display,
    conky_window.drawable,
    conky_window.visual,
    conky_window.width,
    conky_window.height
  )
  local display = cairo_create(cs)
  util_set_cario_font(display, DEFAULT_FONT)  
  cairo_set_source_rgb(display, 1, 1, 1);
  
  local test = MonitorElement:new(nil, display, Point:new(nil, 4, 25))
  if tonumber(conky_parse('${updates}')) > 6 then
    test:render()
    cairo_stroke(display)
  end

  cairo_surface_destroy(cs)
  cairo_destroy(display)
end