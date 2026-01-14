local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Strong: Container
---@operator call(...): Strong
local Strong = class(Element.Container)

---Init Strong Container element
---@param attributes Attributes?
---@param content Content?
function Strong:_init(attributes, content)
    self:super("strong", attributes, content)
end

return Strong
