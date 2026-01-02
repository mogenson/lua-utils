local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Button: Container
local Button = class(Element.Container)

---Init Button Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Button:_init(attributes, content)
    self:super("button", attributes, content)
end

return Button
