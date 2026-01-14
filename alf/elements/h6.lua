local class = require("pl.class")

local Element = require("alf.elements.element")

---@class H6: Container
---@operator call(...): H6
local H6 = class(Element.Container)

---Init H6 Container element
---@param attributes Attributes?
---@param content Content?
function H6:_init(attributes, content)
    self:super("h6", attributes, content)
end

return H6
