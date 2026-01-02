local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Em: Container
local Em = class(Element.Container)

---Init Em Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Em:_init(attributes, content)
    self:super("em", attributes, content)
end

return Em
