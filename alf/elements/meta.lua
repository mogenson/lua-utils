local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Meta: Void
local Meta = class(Element.Void)

---Init Meta Void element
---@param attributes Attributes|nil
---@diagnostic disable-next-line duplicate-set-field
function Meta:_init(attributes)
    self:super("meta", attributes)
end

return Meta
