local class = require("pl.class")

local Element = require("alf.elements.element")

---@class H2: Container
local H2 = class(Element.Container)

---Init H2 Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function H2:_init(attributes, content)
    self:super("h2", attributes, content)
end

return H2
