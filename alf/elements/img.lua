local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Img: Void
local Img = class(Element.Void)

---Init Img Void element
---@param attributes Attributes|nil
---@diagnostic disable-next-line duplicate-set-field
function Img:_init(attributes)
    self:super("img", attributes)
end

return Img
