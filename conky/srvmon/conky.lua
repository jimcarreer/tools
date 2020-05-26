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
  local test1 = MonitorElement(Point(100, 25))
  local test2 = MonitorElement(Point(105, 35))
  test1:render()
  test2:render()
  defaultFont:use()
  cairo_show_text(GLOBALS.DISPLAY, 'Test')
  cairo_stroke(GLOBALS.DISPLAY)
  GLOBALS.destroy()

end