local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Head: Container
local Head = class(Element.Container)

---Init Head Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Head:_init(attributes, content)
    self:super("head", attributes, content)
end

return Head
