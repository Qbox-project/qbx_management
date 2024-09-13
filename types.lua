---@meta

---@alias GroupType 'job' | 'gang'

---@class MenuInfo
---@field groupName string Name of the group
---@field type GroupType Type of group
---@field coords vector3 Coordinates of the zone
---@field size? vector3 uses vec3(1.5, 1.5, 1.5) if not set
---@field rotation? number uses 0.0 if not set

---@class ZoneInfo
---@field coords vector3 coordinates of the zone
---@field size vector3 size of the zone
---@field rotation number rotation of the zone
---@field type GroupType

---@class ContextMenuItem
---@field title? string
---@field menu? string
---@field icon? string | {[1]: string, [2]: string};
---@field iconColor? string
---@field image? string
---@field progress? number
---@field onSelect? fun(args: any)
---@field arrow? boolean
---@field description? string
---@field metadata? string | { [string]: any } | string[]
---@field disabled? boolean
---@field readOnly? boolean
---@field event? string
---@field serverEvent? string
---@field args? any
