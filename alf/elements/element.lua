local class = require("pl.class")

---@alias Tag string
---@alias Attribute string
---@alias Attributes [Attribute]
---@alias ContentProvider string|Element|fun():string
---@alias Content ContentProvider|[ContentProvider]

---An HTML element
---@class Element
---@field tag Tag
---@field class_of fun(self, obj:any):boolean
---@field super fun(self, Tag, ...)
local Element = class()

---Element constructor
---@param tag Tag
function Element:_init(tag)
    self.tag = assert(tag) -- tag is mandatory
end

---Render HTML
---@return string
function Element:render()
    return ""
end

---Generate output string for content
---@param content Content
---@return string
local function stringify(content)
    if type(content) == "string" then
        return content
    elseif Element:class_of(content) then
        return content:render()
    elseif type(content) == "function" then
        return tostring(content())
    elseif type(content) == "table" then
        local html = {}
        for _, c in ipairs(content) do
            table.insert(html, stringify(c))
        end
        return table.concat(html)
    end

    return ""
end

---A void type HTML element
---@class Void: Element
---@field attributes Attributes
Element.Void = class(Element)

---Init void element
---@param tag Tag
---@param attributes Attributes|nil
function Element.Void:_init(tag, attributes)
    self:super(tag)
    self.attributes = attributes or {}
end

---Set void element attributes
---@param attributes Attributes
---@return Void
function Element.Void:setAttributes(attributes)
    self.attributes = attributes
    return self -- allow method chaining
end

---Append attribute to void element
---@param attribute Attribute
---@return Void
function Element.Void:addAttribute(attribute)
    table.insert(self.attributes, attribute)
    return self -- allow method chaining
end

---Render HTML from void element
---@return string
function Element.Void:render()
    local html = {}
    table.insert(html, string.format("<%s", self.tag))
    for _, attribute in ipairs(self.attributes) do
        table.insert(html, string.format(" %s", attribute))
    end
    table.insert(html, ">")
    return table.concat(html)
end

---A container type HTML element
---@class Container: Void
---@field content Content
Element.Container = class(Element.Void)

---Init container element
---@param tag Tag
---@param attributes Attributes|nil
---@param content Content|nil
---@diagnostic disable-next-line duplicate-set-field
function Element.Container:_init(tag, attributes, content)
    self:super(tag, attributes)
    self.content = content or ""
end

---Set container element content
---@param content Content
---@return Container
function Element.Container:setContent(content)
    self.content = content
    return self
end

---Render HTML from container element
---@return string
---@diagnostic disable-next-line duplicate-set-field
function Element.Container:render()
    local html = {}
    table.insert(html, string.format("<%s", self.tag))
    for _, attribute in ipairs(self.attributes) do
        table.insert(html, string.format(" %s", attribute))
    end
    table.insert(html, ">")
    table.insert(html, stringify(self.content))
    table.insert(html, string.format("</%s>", self.tag))
    return table.concat(html)
end

return Element
