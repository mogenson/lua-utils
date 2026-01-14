local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Select: Container
---@operator call(...): Select
local Select = class(Element.Container)

---Init Select Container element
---@param attributes Attributes?
---@param content Content?
function Select:_init(attributes, content)
    self:super("select", attributes, content)
end

return Select
