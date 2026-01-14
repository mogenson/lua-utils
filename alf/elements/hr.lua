local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Hr: Void
---@operator call(...): Hr
local Hr = class(Element.Void)

---Init Hr Void element
---@param attributes Attributes?
---@param content Content?
function Hr:_init(attributes, content)
    self:super("hr", attributes, content)
end

return Hr
