require 'cairo'
require 'lib.util'
require 'lib.point'
require 'lib.monitor'
require 'lib.font'


function conky_main()
  
  if conky_window == nil or tonumber(conky_parse('${updates}')) < 6 then
    return
  end

  defaultFont = Font(
    'UbuntuMono-Regular',
     32.0,
     Color(1.0, 1.0, 1.0, 1.0)
  )

  
  GLOBALS.initialize(conky_window)
  cairo_set_source_rgb(GLOBALS.DISPLAY, 1, 1, 1);
  cairo_set_source_rgb(GLOBALS.OTHER_DISPLAY, 1, 1, 1);
  cairo_set_source_rgb(GLOBALS.OTHER_OTHER_DISPLAY, 1, 1, 1);
  local test1 = MonitorElement(Point(100, 100))
  local test2 = MonitorElement(Point(100, 100))
  test1:render()
  test2.display = GLOBALS.OTHER_DISPLAY
  defaultFont:use()
  defaultFont.display = GLOBALS.OTHER_OTHER_DISPLAY
  cairo_show_text(GLOBALS.DISPLAY, 'Test')
  print(tonumber(conky_parse('${updates}')))
  if tonumber(conky_parse('${updates}')) > 10 then
    cairo_translate(GLOBALS.OTHER_DISPLAY, tonumber(conky_parse('${updates}')) + 300 , 0)
    test2:render()
  end
  cairo_stroke(GLOBALS.DISPLAY)
  cairo_stroke(GLOBALS.OTHER_DISPLAY)
  cairo_stroke(GLOBALS.OTHER_OTHER_DISPLAY)
  GLOBALS.destroy()

end