local class = require("pl.class")

local Element = require("alf.elements.element")

---@class H6: Container
local H6 = class(Element.Container)

---Init H6 Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function H6:_init(attributes, content)
    self:super("h6", attributes, content)
end

return H6
