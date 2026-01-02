local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Body: Container
local Body = class(Element.Container)

---Init Body Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Body:_init(attributes, content)
    self:super("body", attributes, content)
end

return Body
