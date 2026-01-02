local class = require("pl.class")

local Element = require("alf.elements.element")

---@class H3: Container
local H3 = class(Element.Container)

---Init H3 Container element
---@param attributes Attributes|nil
---@param content Content|nil
function H3:_init(attributes, content)
    self:super("h3", attributes, content)
end

return H3
