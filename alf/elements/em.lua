local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Em: Container
---@operator call(...): Em
local Em = class(Element.Container)

---Init Em Container element
---@param attributes Attributes?
---@param content Content?
function Em:_init(attributes, content)
    self:super("em", attributes, content)
end

return Em
