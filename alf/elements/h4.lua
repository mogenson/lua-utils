local class = require("pl.class")

local Element = require("alf.elements.element")

---@class H4: Container
local H4 = class(Element.Container)

---Init H4 Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function H4:_init(attributes, content)
    self:super("h4", attributes, content)
end

return H4
