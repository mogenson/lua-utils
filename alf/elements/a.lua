local class = require("pl.class")

local Element = require("alf.elements.element")

---@class A: Container
---@operator call(...): A
local A = class(Element.Container)

---Init A Container element
---@param attributes Attributes?
---@param content Content?
---@diagnostic disable-next-line duplicate-set-field
function A:_init(attributes, content)
    self:super("a", attributes, content)
end

return A
