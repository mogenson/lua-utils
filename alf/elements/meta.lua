local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Meta: Void
local Meta = class(Element.Void)

---Init Meta Void element
---@param attributes Attributes|nil
---@param content Content|nil
function Meta:_init(attributes, content)
    self:super("meta", attributes, content)
end

return Meta
