local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Li: Container
local Li = class(Element.Container)

---Init Li Container element
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Li:_init(attributes, content)
    self:super("li", attributes, content)
end

return Li
