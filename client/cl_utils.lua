function comma_value(amount)
    local numChanged

    repeat
        amount, numChanged = string.gsub(amount, '^(-?%d+)(%d%d%d)', '%1,%2')
    until numChanged == 0

    return amount
end
