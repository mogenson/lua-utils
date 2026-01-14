local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Img: Void
---@operator call(...): Img
local Img = class(Element.Void)

---Init Img Void element
---@param attributes Attributes?
---@param content Content?
function Img:_init(attributes, content)
    self:super("img", attributes, content)
end

return Img
