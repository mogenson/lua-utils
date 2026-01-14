local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Link: Void
---@operator call(...): Link
local Link = class(Element.Void)

---Init Link Void element
---@param attributes Attributes?
---@param content Content?
function Link:_init(attributes, content)
    self:super("link", attributes, content)
end

return Link
