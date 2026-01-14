local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Span: Container
---@operator call(...): Span
local Span = class(Element.Container)

---Init Span Container element
---@param attributes Attributes?
---@param content Content?
function Span:_init(attributes, content)
    self:super("span", attributes, content)
end

return Span
