-- Pump for Firetrucks
--
-- @author  Grisu118
-- @date  07/01/2014
-- @version v0.1
-- @Descripion: Readme you can find there: https://github.com/Grisu118/Scripts
-- @web: http://grisu118.ch or http://vertexdezign.de
-- Copyright (C) Grisu118, All Rights Reserved.
-- free for noncommerical-usage

--[[
<fuelIndicator firstIndicator="0>4"> <!-- First lamp, is on when tank is not empty -->
		<indicator index="0>0" /> <!-- second -- The other lamps, you can set so much as you want, here are three lamps so first is on when more than 33% is in the tank ... -->
		<indicator index="0>1" /> <!-- third -->
		<indicator index="0>2" />
</fuelIndicator>

]]


pump = {};

function pump.prerequisitesPresent(specializations)
	if not SpecializationUtil.hasSpecialization(Motorized, specializations) then
		print("Warning: Specialization pump needs the specialization Motorized.");
	end;
	if not SpecializationUtil.hasSpecialization(Fillable, specializations) then
		print("Warning: Specialization pump needs the specialization Fillable.");
	end;

	return SpecializationUtil.hasSpecialization(Motorized, specializations) and SpecializationUtil.hasSpecialization(Fillable, specializations);
end;
function pump:load(xmlFile)	
	--Fuel Indicator
	self.count = 0;
	self.percent = 0;
	self.firstIndicator = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.fuelIndicator#firstIndicator"));
	local i = 0;
	self.fuelIndicators = {};
	while true do
		local path = string.format("vehicle.fuelIndicator.indicator(%d)", i);
		local component = Utils.indexToObject(self.components, getXMLString(xmlFile, path .. "#index"));	
		if component == nil then
			break;
		end;
		table.insert(self.fuelIndicators, component);
		i = i + 1;
	end;	

	self.count = table.getn(self.fuelIndicators);
	self.percent = 100 / self.count;
	
	setVisibility(self.firstIndicator, false);
	for j = 0, self.count, 1	do
		setVisibility(self.fuelIndicators[j], false);
	end;
	
	pump.isTurnedOn = false;
	
end;

function pump:delete()
end;
function pump:readStream(streamId, connection)
end;
function pump:writeStream(streamId, connection)
end;

function pump:mouseEvent(posX, posY, isDown, isUp, button)
end;
function pump:keyEvent(unicode, sym, modifier, isDown)
end;
function pump:update(dt)
	if self.isClient then
		if self:getIsActiveForInput() then
			if InputBinding.hasEvent(InputBinding.PUMP_SWITCH) then
				pump:setIsTurnedOn(not pump.isTurnedOn);
			end;
		end;
	end;

end;
function pump:updateTick(dt)
		
		if self.count > 0 and pump.isTurnedOn then
-- TODO Change Fuel Indicator
-- Attention Fuel Indicator only look to own filllevel not to fillevel of a trailer!
			--self.fillLevel = Fillable.getFillLevel;
			--print (self.fillLevel);
			
			if self.fillLevel <= 0 then
				setVisibility(self.firstIndicator, false);
				for j = 0, self.count, 1	do
					setVisibility(self.fuelIndicators[j], false);
				end;
			else 
				local fillpercent = (self.fillLevel) / (self.capacity) * 100;
				--print (fillpercent);
				setVisibility(self.firstIndicator, true);
				local lamps = math.floor(fillpercent / (self.percent));
				--print (lamps);
				for j = 0, lamps, 1 do
					setVisibility(self.fuelIndicators[j], true);
				end;
				for j = lamps + 1, self.count, 1 do
					setVisibility(self.fuelIndicators[j], false);
				end; 
			end;
		end;

end;

function pump:setIsTurnedOn(state)
	pump.isTurnedOn = state;
end;

function pump:draw()
	if self.isClient then
		if pump.isTurnedOn then
			g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_PUMP"), self.typeDesc), InputBinding.PUMP_SWITCH);
		else
			g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_PUMP"), self.typeDesc), InputBinding.PUMP_SWITCH);
		end;
	end;
end;
function pump:attachImplement(implement)
end;
function pump:detachImplement(implementIndex)
end;
function pump:onEnter()
end;
function pump:onLeave()
end;
