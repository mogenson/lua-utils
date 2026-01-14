local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Ul: Container
---@operator call(...): Ul
local Ul = class(Element.Container)

---Init Ul Container element
---@param attributes Attributes?
---@param content Content?
function Ul:_init(attributes, content)
    self:super("ul", attributes, content)
end

return Ul
