local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Header: Container
local Header = class(Element.Container)

---Init Header Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Header:_init(attributes, content)
    self:super("header", attributes, content)
end

return Header
