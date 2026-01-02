local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Button: Container
local Button = class(Element.Container)

---Init Button Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Button:_init(attributes, content)
    self:super("button", attributes, content)
end

return Button
