-- MIT License

-- Copyright (c) 2023 Northn
-- Read more here:
-- * https://github.com/Northn/mimgui_blur/
-- * https://www.blast.hk/threads/179379/

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local ffi = require 'ffi'
local mimgui = require 'mimgui'

local mimgui_blur = {}

local libPath = getWorkingDirectory() .. [[\lib\mimgui_blur\mimgui_blur_lib]]

ffi.cdef[[
    void mimgui_blur_apply(ImDrawList *draw_list, const float radius, const ImU32 color, const float rounding, const ImDrawCornerFlags rounding_corners, const ImVec2 pos_min, const ImVec2 pos_max);
    void mimgui_blur_invalidate();
    float mimgui_blur_version();
]]

local lib = ffi.load(libPath)

--- Apply blur to whole drawlist
--- @param draw_list ImDrawList
--- @param radius number|float|nil Blur radius
--- @param color number|nil Blur color
--- @param rounding number|nil Corners rounding
--- @param rounding_corners ImDrawCornerFlags|nil Corners to round
function mimgui_blur.apply(draw_list, radius, color, rounding, rounding_corners)
    radius = radius or 2
    color = color or -1
    rounding = rounding or 0
    rounding_corners = rounding_corners or 0
    lib.mimgui_blur_apply(draw_list, radius, color, rounding, rounding_corners, mimgui.ImVec2(0, 0), mimgui.ImVec2(math.huge, math.huge))
end

--- Apply blur to current item in drawlist
--- @param draw_list ImDrawList
--- @param radius number|float|nil Blur radius
--- @param color number|nil Blur color
--- @param rounding number|nil Corners rounding
--- @param rounding_corners ImDrawCornerFlags|nil Corners to round
function mimgui_blur.applyItem(draw_list, radius, color, rounding, rounding_corners)
    radius = radius or 2
    color = color or -1
    rounding = rounding or 0
    rounding_corners = rounding_corners or 0
    lib.mimgui_blur_apply(draw_list, radius, color, rounding, rounding_corners, mimgui.GetItemRectMin(), mimgui.GetItemRectMax()) 
end

--- Apply blur to rect in drawlist
--- @param draw_list ImDrawList
--- @param pos_start ImVec2 Start point
--- @param pos_end ImVec2 End point
--- @param radius number|float|nil Blur radius
--- @param color number|nil Blur color
--- @param rounding number|nil Corners rounding
--- @param rounding_corners ImDrawCornerFlags|nil Corners to round
function mimgui_blur.applyRect(draw_list, pos_start, pos_end, radius, color, rounding, rounding_corners)
    radius = radius or 2
    color = color or -1
    rounding = rounding or 0
    rounding_corners = rounding_corners or 0
    lib.mimgui_blur_apply(draw_list, radius, color, rounding, rounding_corners, pos_start, pos_end) 
end

addEventHandler('onD3DDeviceLost', function()
    lib.mimgui_blur_invalidate()
end)

addEventHandler('onScriptTerminate', function(scr)
    if scr == script.this then
        lib.mimgui_blur_invalidate()
    end
end)

mimgui_blur.VERSION = lib.mimgui_blur_version()

return mimgui_blur
