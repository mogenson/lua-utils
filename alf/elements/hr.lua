local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Hr: Void
local Hr = class(Element.Void)

---Init Hr Void element
---@param attributes Attributes|nil
---@diagnostic disable-next-line duplicate-set-field
function Hr:_init(attributes)
    self:super("hr", attributes)
end

return Hr
