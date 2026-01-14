local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Pre: Container
---@operator call(...): Pre
local Pre = class(Element.Container)

---Init Pre Container element
---@param attributes Attributes?
---@param content Content?
function Pre:_init(attributes, content)
    self:super("pre", attributes, content)
end

return Pre
