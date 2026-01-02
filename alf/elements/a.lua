local class = require("pl.class")

local Element = require("alf.elements.element")

---@class A: Container
local A = class(Element.Container)

---Init A Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function A:_init(attributes, content)
    self:super("a", attributes, content)
end

return A
