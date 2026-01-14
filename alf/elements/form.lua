local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Form: Container
---@operator call(...): Form
local Form = class(Element.Container)

---Init Form Container element
---@param attributes Attributes?
---@param content Content?
function Form:_init(attributes, content)
    self:super("form", attributes, content)
end

return Form
