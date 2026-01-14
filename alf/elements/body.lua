local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Body: Container
---@operator call(...): Body
local Body = class(Element.Container)

---Init Body Container element
---@param attributes Attributes?
---@param content Content?
function Body:_init(attributes, content)
    self:super("body", attributes, content)
end

return Body
