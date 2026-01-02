local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Figcaption: Container
local Figcaption = class(Element.Container)

---Init Figcaption Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Figcaption:_init(attributes, content)
    self:super("figcaption", attributes, content)
end

return Figcaption
