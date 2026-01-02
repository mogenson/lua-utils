local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Textarea: Container
local Textarea = class(Element.Container)

---Init Textarea Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Textarea:_init(attributes, content)
    self:super("textarea", attributes, content)
end

return Textarea
