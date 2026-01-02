local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Code: Container
local Code = class(Element.Container)

---Init Code Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Code:_init(attributes, content)
    self:super("code", attributes, content)
end

return Code
