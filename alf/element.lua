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

---@class Meta: Void
Element.Meta = class(Element.Void)

---@param attributes Attributes|nil
function Element.Meta:_init(attributes)
    self:super("meta", attributes)
end

---@class Link: Void
Element.Link = class(Element.Void)

---@param attributes Attributes|nil
function Element.Link:_init(attributes)
    self:super("link", attributes)
end

---@class Input: Void
Element.Input = class(Element.Void)

---@param attributes Attributes|nil
function Element.Input:_init(attributes)
    self:super("input", attributes)
end

---@class Br: Void
Element.Br = class(Element.Void)

---@param attributes Attributes|nil
function Element.Br:_init(attributes)
    self:super("br", attributes)
end

---@class Hr: Void
Element.Hr = class(Element.Void)

---@param attributes Attributes|nil
function Element.Hr:_init(attributes)
    self:super("hr", attributes)
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

---@class Html: Container
Element.Html = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Html:_init(attributes, content)
    self:super("html", attributes, content)
end

---@class Head: Container
Element.Head = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Head:_init(attributes, content)
    self:super("head", attributes, content)
end

---@class Title: Container
Element.Title = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Title:_init(attributes, content)
    self:super("title", attributes, content)
end

---@class Body: Container
Element.Body = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Body:_init(attributes, content)
    self:super("body", attributes, content)
end

---@class Header: Container
Element.Header = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Header:_init(attributes, content)
    self:super("header", attributes, content)
end

---@class H1: Container
Element.H1 = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.H1:_init(attributes, content)
    self:super("h1", attributes, content)
end

---@class H2: Container
Element.H2 = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.H2:_init(attributes, content)
    self:super("h2", attributes, content)
end

---@class H3: Container
Element.H3 = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.H3:_init(attributes, content)
    self:super("h3", attributes, content)
end

---@class H4: Container
Element.H4 = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.H4:_init(attributes, content)
    self:super("h4", attributes, content)
end

---@class H5: Container
Element.H5 = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.H5:_init(attributes, content)
    self:super("h5", attributes, content)
end

---@class Main: Container
Element.Main = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Main:_init(attributes, content)
    self:super("main", attributes, content)
end

---@class Pre: Container
Element.Pre = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Pre:_init(attributes, content)
    self:super("pre", attributes, content)
end

---@class P: Container
Element.P = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.P:_init(attributes, content)
    self:super("p", attributes, content)
end

---@class Footer: Container
Element.Footer = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Footer:_init(attributes, content)
    self:super("footer", attributes, content)
end

---@class Div: Container
Element.Div = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Div:_init(attributes, content)
    self:super("div", attributes, content)
end

---@class Script: Container
Element.Script = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Script:_init(attributes, content)
    self:super("script", attributes, content)
end

---@class Ins: Container
Element.Ins = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Ins:_init(attributes, content)
    self:super("ins", attributes, content)
end

---@class Ins: Container
Element.Mark = class(Element.Container)

---@param attributes Attributes|nil
---@param content Content|nil
function Element.Mark:_init(attributes, content)
    self:super("mark", attributes, content)
end

return Element
