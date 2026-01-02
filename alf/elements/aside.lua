local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Aside: Container
local Aside = class(Element.Container)

---Init Aside Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Aside:_init(attributes, content)
    self:super("aside", attributes, content)
end

return Aside
