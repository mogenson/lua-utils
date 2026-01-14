local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Br: Void
---@operator call(...): Br
local Br = class(Element.Void)

---Init Br Void element
---@param attributes Attributes?
---@param content Content?
function Br:_init(attributes, content)
    self:super("br", attributes, content)
end

return Br
