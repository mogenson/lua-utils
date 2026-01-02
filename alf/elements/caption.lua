local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Caption: Container
local Caption = class(Element.Container)

---Init Caption Container element
---@param attributes Attributes|nil
---@param content Content|nil
function Caption:_init(attributes, content)
    self:super("caption", attributes, content)
end

return Caption
