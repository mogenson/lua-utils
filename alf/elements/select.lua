local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Select: Container
local Select = class(Element.Container)

---Init Select Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Select:_init(attributes, content)
    self:super("select", attributes, content)
end

return Select
