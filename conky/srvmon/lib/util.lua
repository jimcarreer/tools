require 'cairo'

GLOBALS = {
  SURFACE = nil,
  DISPLAY = nil,
}

function GLOBALS.initialize(conky)
  GLOBALS.SURFACE = cairo_xlib_surface_create(
    conky.display,
    conky.drawable,
    conky.visual,
    500,
    500
  )
  GLOBALS.DISPLAY = cairo_create(GLOBALS.SURFACE)
  GLOBALS.OTHER_DISPLAY = cairo_create(GLOBALS.SURFACE)
  GLOBALS.OTHER_OTHER_DISPLAY = cairo_create(GLOBALS.DISPLAY)
end

function GLOBALS.destroy()
  if GLOBALS.SURFACE ~= nil then
    cairo_surface_destroy(GLOBALS.SURFACE)
    GLOBALS.SURFACE = nil
  end
  if GLOBALS.DISPLAY ~= nil then
    cairo_destroy(GLOBALS.DISPLAY)
    GLOBALS.DISPLAY = nil
  end
end

function __class_call(cls, ...)
  if cls['new'] ~= nil then 
    return cls.new(...)
  end
  return {}
end

function __class_index(self, key)
  if key == 'updates' then
    return tonumber(conky_parse('${updates}'))
  elseif key == 'display' then
    if GLOBALS.DISPLAY == nil then
      print('Global display is nil, GLOBALS.initialize(...) has not been called')
    end
    return GLOBALS.DISPLAY;
  end
end

function class(ClassTable)
  ClassTable.__index = ClassTable
  setmetatable(ClassTable, {
    __call = __class_call,
    __index = __class_index,
  })
  return ClassTable
end
