local class = require("pl.class")

local Element = require("alf.elements.element")

---@class P: Container
local P = class(Element.Container)

---Init P Container element
---@param attributes Attributes|nil
---@param content Content|nil
function P:_init(attributes, content)
    self:super("p", attributes, content)
end

return P
