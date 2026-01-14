local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Button: Container
---@operator call(...): Button
local Button = class(Element.Container)

---Init Button Container element
---@param attributes Attributes?
---@param content Content?
function Button:_init(attributes, content)
    self:super("button", attributes, content)
end

return Button
