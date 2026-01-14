local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Thead: Container
---@operator call(...): Thead
local Thead = class(Element.Container)

---Init Thead Container element
---@param attributes Attributes?
---@param content Content?
function Thead:_init(attributes, content)
    self:super("thead", attributes, content)
end

return Thead
