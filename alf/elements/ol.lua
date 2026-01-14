local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Ol: Container
---@operator call(...): Ol
local Ol = class(Element.Container)

---Init Ol Container element
---@param attributes Attributes?
---@param content Content?
function Ol:_init(attributes, content)
    self:super("ol", attributes, content)
end

return Ol
