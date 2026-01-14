local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Nav: Container
---@operator call(...): Nav
local Nav = class(Element.Container)

---Init Nav Container element
---@param attributes Attributes?
---@param content Content?
function Nav:_init(attributes, content)
    self:super("nav", attributes, content)
end

return Nav
