local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Option: Container
local Option = class(Element.Container)

---Init Option Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Option:_init(attributes, content)
    self:super("option", attributes, content)
end

return Option
