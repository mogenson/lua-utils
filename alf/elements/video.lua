local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Video: Container
---@operator call(...): Video
local Video = class(Element.Container)

---Init Video Container element
---@param attributes Attributes?
---@param content Content?
function Video:_init(attributes, content)
    self:super("video", attributes, content)
end

return Video
