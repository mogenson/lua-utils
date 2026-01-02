local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Form: Container
local Form = class(Element.Container)

---Init Form Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Form:_init(attributes, content)
    self:super("form", attributes, content)
end

return Form
