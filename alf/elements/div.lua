local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Div: Container
---@operator call(...): Div
local Div = class(Element.Container)

---Init Div Container element
---@param attributes Attributes?
---@param content Content?
function Div:_init(attributes, content)
    self:super("div", attributes, content)
end

return Div
