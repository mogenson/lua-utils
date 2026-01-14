local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Footer: Container
---@operator call(...): Footer
local Footer = class(Element.Container)

---Init Footer Container element
---@param attributes Attributes?
---@param content Content?
function Footer:_init(attributes, content)
    self:super("footer", attributes, content)
end

return Footer
