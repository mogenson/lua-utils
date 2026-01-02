local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Br: Void
local Br = class(Element.Void)

---Init Br Void element
---@param attributes Attributes|nil
---@param content Content|nil
function Br:_init(attributes, content)
    self:super("br", attributes, content)
end

return Br
