local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Figcaption: Container
---@operator call(...): Figcaption
local Figcaption = class(Element.Container)

---Init Figcaption Container element
---@param attributes Attributes?
---@param content Content?
function Figcaption:_init(attributes, content)
    self:super("figcaption", attributes, content)
end

return Figcaption
