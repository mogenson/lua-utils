local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Meta: Void
---@operator call(...): Meta
local Meta = class(Element.Void)

---Init Meta Void element
---@param attributes Attributes?
---@param content Content?
function Meta:_init(attributes, content)
    self:super("meta", attributes, content)
end

return Meta
