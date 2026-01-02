local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Span: Container
local Span = class(Element.Container)

---Init Span Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Span:_init(attributes, content)
    self:super("span", attributes, content)
end

return Span
