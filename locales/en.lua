local Translations = {
    menu = {
        grade = 'Grade: ',
        expel_gang = 'Expel Gang Member',
        fire_employee = 'Fire Employee',
        manage_gang = 'Manage Gang Members',
        manage_employees = 'Manage Employees',
        citizen_id = 'Citizen ID: ',
        id = 'ID: ',
        hire_gang = 'Hire Gang Members',
        hire_civilians = 'Hire Nearby Civilians',
        hire_employees = 'Hire Employees',
        check_gang = 'Check your Gang List',
        check_employee = 'Check your Gang List',
        gang_storage = 'Open Gang Storage',
        business_storage = 'Open Business Storage',
        gang_menu = 'Gang Menu',
        boss_menu = 'Boss Menu',
        gang_management = '[E] - Open Gang Management',
        boss_management = '[E] - Open Boss Management',
    },
    error = {
        cant_promote = 'You can\'t promote this player',
        not_around = 'This person is not in city',
        grade_not_exist = 'Grade does not exist',
        couldnt_hire = 'Couldn\'t hire this person',
        kick_yourself = 'You can\'t kick yourself out of the gang',
        fire_yourself = 'You can\'t fire yourself',
        kick_boss = 'You can\'t kick your boss',
        you_gang_fired = 'You have been expelled from the gang!',
        you_job_fired = 'You have been fired! Good luck.',
        unable_fire = 'You are unable to fire this person',
        person_doesnt_exist = 'This person doesn\'t seem to exist',
        fire_boss = 'You can\'t fire your boss',
        gang_fired = 'Gang member fired',
        job_fired = 'Employee fired',
    },
    success = {
        promoted = 'Successfully promoted!',
        promoted_to = 'You have been promoted to ',
        hired_to = 'You have been hired into ',
        hired_into = 'You hired %{who} into %{where}',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

