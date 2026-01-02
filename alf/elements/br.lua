local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Br: Void
local Br = class(Element.Void)

---Init Br Void element
---@param attributes Attributes|nil
---@diagnostic disable-next-line duplicate-set-field
function Br:_init(attributes)
    self:super("br", attributes)
end

return Br
