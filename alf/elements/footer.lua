local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Footer: Container
local Footer = class(Element.Container)

---Init Footer Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Footer:_init(attributes, content)
    self:super("footer", attributes, content)
end

return Footer
