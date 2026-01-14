local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Code: Container
---@operator call(...): Code
local Code = class(Element.Container)

---Init Code Container element
---@param attributes Attributes?
---@param content Content?
function Code:_init(attributes, content)
    self:super("code", attributes, content)
end

return Code
