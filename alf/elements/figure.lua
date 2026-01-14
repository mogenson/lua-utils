local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Figure: Container
---@operator call(...): Figure
local Figure = class(Element.Container)

---Init Figure Container element
---@param attributes Attributes?
---@param content Content?
function Figure:_init(attributes, content)
    self:super("figure", attributes, content)
end

return Figure
