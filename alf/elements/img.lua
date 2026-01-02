local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Img: Void
local Img = class(Element.Void)

---Init Img Void element
---@param attributes Attributes|nil
---@param content Content|nil
function Img:_init(attributes, content)
    self:super("img", attributes, content)
end

return Img
