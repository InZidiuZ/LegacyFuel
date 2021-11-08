RegisterNetEvent('fuel:pay', function(price, source)
	local Player = QBCore.Functions.GetPlayer(source)
	local amount = math.floor(price + 0.5)

	if price > 0 then
		Player.Functions.RemoveMoney('cash', amount)
	end
end)
