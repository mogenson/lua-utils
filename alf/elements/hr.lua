local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Hr: Void
local Hr = class(Element.Void)

---Init Hr Void element
---@param attributes Attributes|nil
---@param content Content|nil
function Hr:_init(attributes, content)
    self:super("hr", attributes, content)
end

return Hr
