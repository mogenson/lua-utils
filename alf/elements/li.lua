local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Li: Container
---@operator call(...): Li
local Li = class(Element.Container)

---Init Li Container element
---@param attributes Attributes?
---@param content Content?
function Li:_init(attributes, content)
    self:super("li", attributes, content)
end

return Li
