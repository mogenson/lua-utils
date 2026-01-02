local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Tr: Container
local Tr = class(Element.Container)

---Init Tr Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Tr:_init(attributes, content)
    self:super("tr", attributes, content)
end

return Tr
