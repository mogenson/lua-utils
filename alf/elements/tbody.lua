local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Tbody: Container
---@operator call(...): Tbody
local Tbody = class(Element.Container)

---Init Tbody Container element
---@param attributes Attributes?
---@param content Content?
function Tbody:_init(attributes, content)
    self:super("tbody", attributes, content)
end

return Tbody
