local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Label: Container
local Label = class(Element.Container)

---Init Label Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Label:_init(attributes, content)
    self:super("label", attributes, content)
end

return Label
