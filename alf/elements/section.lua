local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Section: Container
---@operator call(...): Section
local Section = class(Element.Container)

---Init Section Container element
---@param attributes Attributes?
---@param content Content?
function Section:_init(attributes, content)
    self:super("section", attributes, content)
end

return Section
