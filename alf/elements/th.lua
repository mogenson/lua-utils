local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Th: Container
local Th = class(Element.Container)

---Init Th Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Th:_init(attributes, content)
    self:super("th", attributes, content)
end

return Th
