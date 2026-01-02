local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Ul: Container
local Ul = class(Element.Container)

---Init Ul Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Ul:_init(attributes, content)
    self:super("ul", attributes, content)
end

return Ul
