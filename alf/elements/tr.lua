local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Tr: Container
---@operator call(...): Tr
local Tr = class(Element.Container)

---Init Tr Container element
---@param attributes Attributes?
---@param content Content?
function Tr:_init(attributes, content)
    self:super("tr", attributes, content)
end

return Tr
