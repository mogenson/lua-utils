local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Ins: Container
local Ins = class(Element.Container)

---Init Ins Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Ins:_init(attributes, content)
    self:super("ins", attributes, content)
end

return Ins
