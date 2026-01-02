local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Video: Container
local Video = class(Element.Container)

---Init Video Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Video:_init(attributes, content)
    self:super("video", attributes, content)
end

return Video
