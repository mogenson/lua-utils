local class = require("pl.class")

local Element = require("alf.elements.element")

---@class Link: Void
local Link = class(Element.Void)

---Init Link Void element
---@param attributes Attributes|nil
---@param content Content|nil
function Link:_init(attributes, content)
    self:super("link", attributes, content)
end

return Link
