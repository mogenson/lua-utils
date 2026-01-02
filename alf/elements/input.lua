local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Input: Void
local Input = class(Element.Void)

---Init Input Void element
---@param attributes Attributes|nil
---@diagnostic disable-next-line duplicate-set-field
function Input:_init(attributes)
    self:super("input", attributes)
end

return Input
