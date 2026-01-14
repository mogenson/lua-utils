local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Aside: Container
---@operator call(...): Aside
local Aside = class(Element.Container)

---Init Aside Container element
---@param attributes Attributes?
---@param content Content?
function Aside:_init(attributes, content)
    self:super("aside", attributes, content)
end

return Aside
