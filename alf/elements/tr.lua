local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Tr: Container
local Tr = class(Element.Container)

---Init Tr Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Tr:_init(attributes, content)
    self:super("tr", attributes, content)
end

return Tr
