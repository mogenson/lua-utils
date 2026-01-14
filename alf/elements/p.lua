local class = require("pl.class")

local Element = require("alf.elements.element")

---@class P: Container
---@operator call(...): P
local P = class(Element.Container)

---Init P Container element
---@param attributes Attributes?
---@param content Content?
function P:_init(attributes, content)
    self:super("p", attributes, content)
end

return P
