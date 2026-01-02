local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Section: Container
local Section = class(Element.Container)

---Init Section Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Section:_init(attributes, content)
    self:super("section", attributes, content)
end

return Section
