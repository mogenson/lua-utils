local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Thead: Container
local Thead = class(Element.Container)

---Init Thead Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Thead:_init(attributes, content)
    self:super("thead", attributes, content)
end

return Thead
