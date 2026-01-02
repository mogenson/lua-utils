local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Figure: Container
local Figure = class(Element.Container)

---Init Figure Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Figure:_init(attributes, content)
    self:super("figure", attributes, content)
end

return Figure
