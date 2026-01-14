local class = require("pl.class")

local Element = require("alf.elements.element")

---@class H2: Container
---@operator call(...): H2
local H2 = class(Element.Container)

---Init H2 Container element
---@param attributes Attributes?
---@param content Content?
function H2:_init(attributes, content)
    self:super("h2", attributes, content)
end

return H2
