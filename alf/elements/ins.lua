local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Ins: Container
---@operator call(...): Ins
local Ins = class(Element.Container)

---Init Ins Container element
---@param attributes Attributes?
---@param content Content?
function Ins:_init(attributes, content)
    self:super("ins", attributes, content)
end

return Ins
