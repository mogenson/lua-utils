local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Input: Void
---@operator call(...): Input
local Input = class(Element.Void)

---Init Input Void element
---@param attributes Attributes?
---@param content Content?
function Input:_init(attributes, content)
    self:super("input", attributes, content)
end

return Input
