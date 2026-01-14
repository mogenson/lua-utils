local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Option: Container
---@operator call(...): Option
local Option = class(Element.Container)

---Init Option Container element
---@param attributes Attributes?
---@param content Content?
function Option:_init(attributes, content)
    self:super("option", attributes, content)
end

return Option
