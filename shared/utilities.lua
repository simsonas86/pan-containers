Utility = {
	notify = function(title, description, type)
		-- put your own notification system here if needed
		-- example:
		-- exports['myNotificationSystem']:SendAlert(title, description, type)
		lib.notify({
			title = title,
			description = description or '',
			type = type,
			duration = 5000
		})
	end,


}