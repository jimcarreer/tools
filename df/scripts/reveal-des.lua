-- Reveal all designated tiles on the current layer
-- Modified by gameboy17 from drain-aquifer
--[====[

reveal-des
=============
Reveal all designated tiles on the current layer.
Intended to prevent digging cancellations due to warm/damp stone.

If an argument is given, reveals designated tiles that many layers up. Defaults to 1.
Give a negative number to reveal that many layers down.


]====]

if ... then height = tonumber(...) else height = 1 end

local function reveal(height)

   local startlayer
   local endlayer
   if height >= 0 then
      startlayer = df.global.window_z
      endlayer = startlayer + height
   else
      endlayer = df.global.window_z
      startlayer = endlayer + height
      height = height * -1
   end     
   print("Revealing designated tiles in "..height.." layer"..((height ~= 1) and "s" or "")..".")

    local tile_count = 0
    for k, block in ipairs(df.global.world.map.map_blocks) do
      if block.map_pos.z >= startlayer and block.map_pos.z < endlayer then
         for x, row in ipairs(block.designation) do
            for y, tile in ipairs(row) do
               if tile.dig > 0 and tile.hidden then             
                  tile_count = tile_count+1
                  tile.hidden = false
               end
            end
         end
      end
    end

    print("Revealed "..tile_count.." designated tile"..((tile_count ~= 1) and "s" or "")..".")
end

reveal(height)