local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Ol: Container
local Ol = class(Element.Container)

---Init Ol Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Ol:_init(attributes, content)
    self:super("ol", attributes, content)
end

return Ol
