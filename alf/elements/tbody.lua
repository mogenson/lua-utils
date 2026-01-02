local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Tbody: Container
local Tbody = class(Element.Container)

---Init Tbody Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Tbody:_init(attributes, content)
    self:super("tbody", attributes, content)
end

return Tbody
