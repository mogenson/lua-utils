local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Header: Container
---@operator call(...): Header
local Header = class(Element.Container)

---Init Header Container element
---@param attributes Attributes?
---@param content Content?
function Header:_init(attributes, content)
    self:super("header", attributes, content)
end

return Header
