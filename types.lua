---@meta

---@alias GroupType 'job' | 'gang'

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
