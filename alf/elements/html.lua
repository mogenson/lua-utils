local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Html: Container
local Html = class(Element.Container)

---Init Html Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Html:_init(attributes, content)
    self:super("html", attributes, content)
end

return Html
