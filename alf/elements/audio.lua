local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Audio: Container
---@operator call(...): Audio
local Audio = class(Element.Container)

---Init Audio Container element
---@param attributes Attributes?
---@param content Content?
function Audio:_init(attributes, content)
    self:super("audio", attributes, content)
end

return Audio
