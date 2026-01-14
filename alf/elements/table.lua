local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Table: Container
---@operator call(...): Table
local Table = class(Element.Container)

---Init Table Container element
---@param attributes Attributes?
---@param content Content?
function Table:_init(attributes, content)
    self:super("table", attributes, content)
end

return Table
