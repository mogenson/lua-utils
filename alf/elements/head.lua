local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Head: Container
---@operator call(...): Head
local Head = class(Element.Container)

---Init Head Container element
---@param attributes Attributes?
---@param content Content?
function Head:_init(attributes, content)
    self:super("head", attributes, content)
end

return Head
