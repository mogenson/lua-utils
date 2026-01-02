local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Pre: Container
local Pre = class(Element.Container)

---Init Pre Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Pre:_init(attributes, content)
    self:super("pre", attributes, content)
end

return Pre
