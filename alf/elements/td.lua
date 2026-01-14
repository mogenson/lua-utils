local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Td: Container
---@operator call(...): Td
local Td = class(Element.Container)

---Init Td Container element
---@param attributes Attributes?
---@param content Content?
function Td:_init(attributes, content)
    self:super("td", attributes, content)
end

return Td
