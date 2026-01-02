local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Td: Container
local Td = class(Element.Container)

---Init Td Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Td:_init(attributes, content)
    self:super("td", attributes, content)
end

return Td
