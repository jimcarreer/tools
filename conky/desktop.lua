
require 'cairo'

settings = {
  globals = {
    -- center of the screen / display
    center_x = 713,
    center_y = 425,
    -- font parameters
    font_txt = {
      name = 'UbuntuMono',
      size = 14.0,
      slant = CAIRO_FONT_SLANT_NORMAL,
      weight = CAIRO_FONT_WEIGHT_BOLD
    },
    font_head = {
      name = 'UbuntuMono',
      size = 16.0,
      slant = CAIRO_FONT_SLANT_NORMAL,
      weight = CAIRO_FONT_WEIGHT_BOLD
    }
  },
  cpus = {
    cores = 12,
    -- Angles for NE quadrant of circle
    quad0_start = 270  * (math.pi/180.0),
    quad0_end   = 360  * (math.pi/180.0),
    -- Angles for SW quadrant of circle
    quad2_start = 90   * (math.pi/180.0),
    quad2_end   = 180  * (math.pi/180.0),
    -- Minimum raidus of cpu gauge arcs
    -- and radial increment
    minimum_radius   = 156,
    radius_increment = 14.0,
    -- Text x / y locations for NE quadrant
    quad0_x    = 645,
    quad0_y    = 273,
    -- Text x / y locations for SW quadrant
    quad2_x    = 720,
    quad2_y    = 585
  },
  procs = {
    quad1_x    = 866,
    quad1_y    = 440,
    increment  = 14.0
  }
}

function util_set_cario_font(cr, font)
  cairo_select_font_face(cr, font['name'], font['slant'], font['weight'])
  cairo_set_font_size(cr, font['size'])
end

function draw_core_gauge(cr, corenum)

  local cores  = settings['cpus'   ]['cores']
  local radius = settings['cpus'   ]['minimum_radius']
  local radinc = settings['cpus'   ]['radius_increment']
  local angle1 = settings['cpus'   ]['quad0_start']
  local angle2 = settings['cpus'   ]['quad0_end']
  local xc     = settings['globals']['center_x']
  local yc     = settings['globals']['center_y']
  local txt_x  = settings['cpus'   ]['quad0_x']
  local txt_y  = settings['cpus'   ]['quad0_y']
  local font   = settings['globals']['font_txt']
  local format = 'CPU%02d %03d'

  if (corenum+1 > cores / 2) then
    radius = radius + (radinc*(corenum-(cores/2)))
    angle1 = settings['cpus']['quad2_start']
    angle2 = settings['cpus']['quad2_end']
    txt_x  = settings['cpus']['quad2_x']
    txt_y  = settings['cpus']['quad2_y']
    txt_y  = txt_y + (radinc*(corenum-(cores/2)))
  else
    radius = radius + (radinc*(corenum))
    txt_y  = txt_y - (radinc*(corenum))
  end

  -- Draw transparent background arc
  cairo_set_source_rgba(cr, 1, 1, 1, .25)
  cairo_set_line_width(cr, 10.0)
  cairo_arc(cr, xc, yc, radius, angle1, angle2)
  cairo_stroke(cr)

  -- Draw usage arc
  local usage = conky_parse(string.format('${cpu cpu%d}', corenum))

  -- Debug test alignment
  --if (corenum == 0) then usage = 100 end

  local angle_max = angle2 - angle1
  cairo_set_source_rgba(cr, 1, 1, 1, 1)
  angle2 = angle1 + ((usage/100.0)*angle_max)
  cairo_arc(cr, xc, yc, radius, angle1, angle2)

  -- Draw usage text
  local usage_txt = ""
  if (corenum+1 > cores / 2) then
    usage_txt = string.format('%03d CPU%02d', usage, corenum)
  else
    usage_txt = string.format('CPU%02d %03d', corenum, usage)
  end

  util_set_cario_font(cr, font)
  cairo_move_to(cr, txt_x, txt_y)
  cairo_show_text(cr, usage_txt)
  cairo_stroke(cr)
end

function draw_all_cores(cr)
  for corenum = 0, settings['cpus']['cores']-1 do
    draw_core_gauge(cr, corenum)
  end
end

function draw_top_procs_cpu(cr)

  local txt_x     = settings['procs'  ]['quad1_x']
  local txt_y     = settings['procs'  ]['quad1_y']
  local inc_y     = settings['procs'  ]['increment']
  local font_txt  = settings['globals']['font_txt']
  local font_head = settings['globals']['font_head']


  -- Draw header
  local cpu = tonumber(conky_parse('${cpu cpu}'))
  util_set_cario_font(cr, font_head)
  cairo_move_to(cr, txt_x, txt_y)
  local head_txt = string.format('TOP CPU USAGE     %3d%%',cpu)
  cairo_show_text(cr, head_txt)
  cairo_set_line_width(cr, 3.0)
  txt_y = txt_y + 5
  cairo_move_to(cr, txt_x, txt_y)
  cairo_line_to(cr, txt_x+180, txt_y)
  txt_y = txt_y + 16

  util_set_cario_font(cr, font_txt)
  for procnum = 1, 8 do
    local name  = conky_parse(string.format('${top name %d}', procnum))
    local usage = conky_parse(string.format('${top cpu %d}', procnum))
    usage = string.gsub(usage, "%s+", "")
    usage = tonumber(usage)
    name  = string.upper(name)

    -- Debug test alignment
    --if (procnum == 1) then usage = 100.00 end
    --if (procnum == 1) then name = "123456789ABCDEFG" end

    local proc_txt = string.format('%6.02f : %.16s', usage, name)
    cairo_move_to(cr, txt_x, txt_y)
    cairo_show_text(cr, proc_txt)
    txt_y = txt_y + inc_y
  end
  cairo_stroke(cr)
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
    
    local updates = conky_parse('${updates}')
    update_num = tonumber(updates)
    
    if update_num > 6 then
      -- go_gauge_rings(display)
      draw_all_cores(display)
      draw_top_procs_cpu(display)
    end

    cairo_surface_destroy(cs)
    cairo_destroy(display)

end

