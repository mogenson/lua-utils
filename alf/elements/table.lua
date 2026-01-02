local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Table: Container
local Table = class(Element.Container)

---Init Table Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Table:_init(attributes, content)
    self:super("table", attributes, content)
end

return Table
