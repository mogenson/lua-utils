local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Link: Void
local Link = class(Element.Void)

---Init Link Void element
---@param attributes Attributes|nil
---@diagnostic disable-next-line duplicate-set-field
function Link:_init(attributes)
    self:super("link", attributes)
end

return Link
