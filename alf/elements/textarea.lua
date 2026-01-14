local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Textarea: Container
---@operator call(...): Textarea
local Textarea = class(Element.Container)

---Init Textarea Container element
---@param attributes Attributes?
---@param content Content?
function Textarea:_init(attributes, content)
    self:super("textarea", attributes, content)
end

return Textarea
