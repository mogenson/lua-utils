local class = require("pl.class")

local Element = require("alf.elements.element")

---@class H1: Container
local H1 = class(Element.Container)

---Init H1 Container element
---@param attributes Attributes|nil
---@param content Content|nil
function H1:_init(attributes, content)
    self:super("h1", attributes, content)
end

return H1
