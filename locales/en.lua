local Translations = {
    menu = {
        gang_manage_members_title = "Manage Gang Members",
        gang_manage_members_description = "Recruit or Fire Gang Members",
        gang_hire_member_title = "Recruit Members",
        gang_hire_member_description = "Hire Gang Members",
        gang_stash_title = "Storage Access",
        gang_stash_description = "Open Gang Stash",
        gang_outfits_title = "Outfits",
        gang_outfits_description = "Change Clothes",
        gang_money_management_title = "Money Management",
        gang_money_management_description = "Check your Gang Balance"
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})