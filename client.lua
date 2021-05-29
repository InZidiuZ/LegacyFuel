local isNearPump = false
local pumpLocation = nil
local isFueling = false
local currentFuel = 0.0
local currentFuel2 = 0.0
local currentCost = 0.0

local output = {
	['price'] = Config.stock.default_price,
	['stock'] = Config.stock.default_stock,
}

function close()
	SetNuiFocus(false, false)
	SendNUIMessage({ action = false })
	isFueling = false
end

function open(vehicle,data)
	SetNuiFocus(true, true)
	SendNUIMessage({ action = true, fuel = GetVehicleFuelLevel(vehicle), data = data })
end

AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() ~= name then return end
    close()
end)

RegisterNUICallback('escape', function(data, cb)
    close()
end)

RegisterNetEvent('renzu_fuel:close')
AddEventHandler('renzu_fuel:close',function()
	close()
end)

function ManageFuelUsage(vehicle)
	if IsVehicleEngineOn(vehicle) then
		SetVehicleFuelLevel(vehicle,GetVehicleFuelLevel(vehicle) - Config.FuelUsage[Round(GetVehicleCurrentRpm(vehicle),1)] * (Config.Classes[GetVehicleClass(vehicle)] or 1.0) / 10)
		DecorSetFloat(vehicle,Config.FuelDecor,GetVehicleFuelLevel(vehicle))
	end
end

Citizen.CreateThread(function()
	if Config.Managefuel then
		DecorRegister(Config.FuelDecor,1)
		while true do
			Citizen.Wait(2000)
			local ped = PlayerPedId()
			if IsPedInAnyVehicle(ped) then
				local vehicle = GetVehiclePedIsIn(ped)
				if GetPedInVehicleSeat(vehicle,-1) == ped then
					ManageFuelUsage(vehicle)
				end
			end
		end
	end
end)

function FindNearestFuelPump()
	local coords = GetEntityCoords(PlayerPedId())
	local fuelPumps = {}
	local handle,object = FindFirstObject()
	local success

	repeat
		if Config.PumpModels[GetEntityModel(object)] then
			table.insert(fuelPumps,object)
		end

		success,object = FindNextObject(handle,object)
	until not success

	EndFindObject(handle)

	local pumpObject = 0
	local pumpDistance = 1000

	for k,v in pairs(fuelPumps) do
		local dstcheck = GetDistanceBetweenCoords(coords,GetEntityCoords(v))

		if dstcheck < pumpDistance then
			pumpDistance = dstcheck
			pumpObject = v
		end
	end
	return pumpObject,pumpDistance
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(2000)
		local pumpObject,pumpDistance = FindNearestFuelPump()
		if pumpDistance < 2.0 then
			pumpLocation = nil
			for k,v in pairs(Config.GasStation) do
				if GetDistanceBetweenCoords(vector3(v[1],v[2],v[3]),GetEntityCoords(pumpObject)) <= v[4] then
					pumpLocation = k
				end
			end
			isNearPump = pumpObject
		else
			isNearPump = false
			Citizen.Wait(math.ceil(pumpDistance*20))
		end
	end
end)

RegisterNetEvent("renzu_fuel:syncfuel")
AddEventHandler("renzu_fuel:syncfuel",function(index,change,FuelDecor)
	if NetworkDoesNetworkIdExist(index) then
		local v = NetToVeh(index)
		if DoesEntityExist(v) then
			SetVehicleFuelLevel(v,(GetVehicleFuelLevel(v) + change))
			DecorSetFloat(v,FuelDecor,GetVehicleFuelLevel(v))
		end
	end
end)

RegisterNetEvent('renzu_fuel:jerrycan')
AddEventHandler('renzu_fuel:jerrycan',function()
	GiveWeaponToPed(PlayerPedId(),883325847,4500,false,true)
end)

function Round(num,numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num*mult+0.5) / mult
end

--[[ Creates gas station and blips ]]--
Citizen.CreateThread(function()
	Wait(1000)
	local blip = {}
	for k,v in pairs(Config.GasStation) do
		if not DoesBlipExist(blip[k]) then
			local x,y,z = table.unpack(v)
			blip[k] = AddBlipForCoord(x,y,z)
			SetBlipSprite(blip[k], 361)
			SetBlipDisplay(blip[k], 4)
			SetBlipScale(blip[k], 0.5)
			SetBlipColour(blip[k], 1)
			SetBlipAsShortRange(blip[k], true)

			BeginTextCommandSetBlipName(k)
			AddTextEntry(k, k)
			EndTextCommandSetBlipName(blip[k])
		end
	end
end)

RegisterNetEvent('renzu_fuel:refuelFromPump')
AddEventHandler('renzu_fuel:refuelFromPump',function(pumpObject,ped,vehicle)
	currentFuel = GetVehicleFuelLevel(vehicle)
	TaskTurnPedToFaceEntity(ped,vehicle,5000)
	LoadAnimDict("timetable@gardener@filling_can")
	TaskPlayAnim(ped,"timetable@gardener@filling_can","gar_ig_5_filling_can",2.0,8.0,-1,50,0,0,0,0)

	while isFueling do
		Citizen.Wait(4)
        local oldFuel = DecorGetFloat(vehicle,Config.FuelDecor)
		local fuelToAdd = math.random(1,2) / 100.0

		for k,v in pairs(Config.DisableKeys) do
			DisableControlAction(0,v)
		end

		local vehicleCoords = GetEntityCoords(vehicle)
		if not pumpObject then
			DrawText3Ds(vehicleCoords.x,vehicleCoords.y,vehicleCoords.z + 0.5,"PRESS ~g~E ~w~TO CANCEL")
			DrawText3Ds(vehicleCoords.x,vehicleCoords.y,vehicleCoords.z + 0.34,"GALLON: ~b~"..Round(GetAmmoInPedWeapon(ped,883325847) / 4500 * 100,1).."%~w~    TANK: ~y~"..Round(currentFuel,1).."%")
			if GetAmmoInPedWeapon(ped,883325847) - fuelToAdd * 100 >= 0 then
				currentFuel = oldFuel + fuelToAdd
				SetPedAmmo(ped,883325847,math.floor(GetAmmoInPedWeapon(ped,883325847) - fuelToAdd * 100))
			else
				isFueling = false
			end
		end

		if not IsEntityPlayingAnim(ped,"timetable@gardener@filling_can","gar_ig_5_filling_can",3) then
			TaskPlayAnim(ped,"timetable@gardener@filling_can","gar_ig_5_filling_can",2.0,8.0,-1,50,0,0,0,0)
		end

		if currentFuel > 100.0 then
			currentFuel = 100.0
			isFueling = false
		end

		SetVehicleFuelLevel(vehicle,currentFuel)
		DecorSetFloat(vehicle,Config.FuelDecor,GetVehicleFuelLevel(vehicle))

		if IsControlJustReleased(0,38) or DoesEntityExist(GetPedInVehicleSeat(vehicle,-1)) then
			isFueling = false
		end
	end

	ClearPedTasks(ped)
	RemoveAnimDict("timetable@gardener@filling_can")
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(2000)
		local ped = PlayerPedId()
		local sleep = 2000
		while not isFueling and ((isNearPump and GetEntityHealth(isNearPump) > 0) or (GetSelectedPedWeapon(ped) == 883325847 and not isNearPump)) do
			if isNearPump then
				sleep = 1
			end
			if IsPedInAnyVehicle(ped) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped),-1) == ped then
				local pumpCoords = GetEntityCoords(isNearPump)
				DrawText3Ds(pumpCoords.x,pumpCoords.y,pumpCoords.z + 1.2,"GET OUT OF ~y~VEHICLE ~w~TO FUEL")
			else
				local vehicle = GetPlayersLastVehicle()
				local vehicleCoords = GetEntityCoords(vehicle)
				if DoesEntityExist(vehicle) and GetDistanceBetweenCoords(GetEntityCoords(ped),vehicleCoords) < 3.5 then
					if not DoesEntityExist(GetPedInVehicleSeat(vehicle,-1)) then
						local stringCoords = GetEntityCoords(isNearPump)
						local canFuel = true
						if GetSelectedPedWeapon(ped) == 883325847 then
							stringCoords = vehicleCoords
							if GetAmmoInPedWeapon(ped,883325847) < 100 then
								canFuel = false
							end
						end

						if GetVehicleFuelLevel(vehicle) < 99 and canFuel then
							DrawText3Ds(stringCoords.x,stringCoords.y,stringCoords.z + 1.2,"Press ~g~E ~w~to fuel")
							if IsControlJustReleased(0,38) then
								if isNearPump then
									open(vehicle,output)
									isFueling = true
									paid = false
								else
									isFueling = true
									TriggerEvent('renzu_fuel:refuelFromPump',isNearPump,ped,vehicle)
								end
							end
						elseif not canFuel then
							DrawText3Ds(stringCoords.x,stringCoords.y,stringCoords.z + 1.2,"~o~Cant Refuel")
						else
							DrawText3Ds(stringCoords.x,stringCoords.y,stringCoords.z + 1.2,"~g~FULL TANK")
						end
					end
				elseif isNearPump then
					local stringCoords = GetEntityCoords(isNearPump)
					DrawText3Ds(stringCoords.x,stringCoords.y,stringCoords.z + 1.2,"Press ~g~E ~w~to Buy Jerrycan")
					if IsControlJustReleased(0,38) then
						TriggerServerEvent('renzu_fuel:payfuel',10000,true)
					end
				end
			end
			Citizen.Wait(sleep)
		end
	end
end)

function ShowHelpNotification(msg, thisFrame, beep, duration)
	AddTextEntry('notify_gas', msg)
    DisplayHelpTextThisFrame('notify_gas', thisFrame)
end

RegisterNetEvent('renzu_fuel:Notify')
AddEventHandler('renzu_fuel:Notify',function(msg)
	ShowHelpNotification(msg, false)
end)

RegisterNUICallback('pay', function(data, cb)
	local vehicle = GetPlayersLastVehicle()
    local new_perc = tonumber(data.new_perc)
	if not paid then
		if DoesEntityExist(vehicle) and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()),GetEntityCoords(vehicle)) < 5 then
			TriggerServerEvent('renzu_fuel:payfuel',math.floor(new_perc),false,VehToNet(vehicle),math.floor(new_perc),Config.FuelDecor,pumpLocation)
			paid = true
		end
	end
end)

RegisterNUICallback('startanim',function(data,cb)
	local ped = PlayerPedId()
	local vehicle = GetPlayersLastVehicle()
	TaskTurnPedToFaceEntity(ped,vehicle,5000)
	LoadAnimDict("timetable@gardener@filling_can")
	TaskPlayAnim(ped,"timetable@gardener@filling_can","gar_ig_5_filling_can",2.0,8.0,-1,50,0,0,0,0)
end)

RegisterNUICallback('removeanim',function(data,cb)
	local ped = PlayerPedId()
	ClearPedTasks(ped)
	RemoveAnimDict("timetable@gardener@filling_can")
end)

function DrawText3Ds(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)

	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,150)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text))/370
	DrawRect(_x,_y+0.0125,0.01+factor,0.03,0,0,0,80)
end

function LoadAnimDict(dict)
	if not HasAnimDictLoaded(dict) then
		RequestAnimDict(dict)
		while not HasAnimDictLoaded(dict) do
			Citizen.Wait(10)
		end
	end
end