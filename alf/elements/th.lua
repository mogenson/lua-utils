local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Th: Container
---@operator call(...): Th
local Th = class(Element.Container)

---Init Th Container element
---@param attributes Attributes?
---@param content Content?
function Th:_init(attributes, content)
    self:super("th", attributes, content)
end

return Th
