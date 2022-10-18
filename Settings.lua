local settings = {}

settings.Version = "v2"

--[[ Invite Code ]]--
settings.InviteCodeEnabled = true

settings.Letters = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
settings.Numbers = {1,2,3,4,5,6,7,8,9,0}


-- %l = random lower letter
-- %L = random upper letter
-- %a = random lower or upper letter
-- %n = random number
-- %r = random lower digit
-- %R = random upper digit
-- %x = random lower or upper digit
settings.InviteFormat = "%l%l%l%l-%n%n%n"

--[[ Debug ]]--

settings.WarnDeprecated = true -- not implemented

return settings
