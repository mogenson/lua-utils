local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Strong: Container
local Strong = class(Element.Container)

---Init Strong Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Strong:_init(attributes, content)
    self:super("strong", attributes, content)
end

return Strong
