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


Pump = {};

function Pump.prerequisitesPresent(specializations)
	if not SpecializationUtil.hasSpecialization(Motorized, specializations) then
		print("Warning: Specialization Pump needs the specialization Motorized.");
	end;
	if not SpecializationUtil.hasSpecialization(Fillable, specializations) then
		print("Warning: Specialization Pump needs the specialization Fillable.");
	end;

	return SpecializationUtil.hasSpecialization(Motorized, specializations) and SpecializationUtil.hasSpecialization(Fillable, specializations);
end;
function Pump:load(xmlFile)	
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
	
	Pump.isTurnedOn = false;
	
end;

function Pump:delete()
end;
function Pump:readStream(streamId, connection)
end;
function Pump:writeStream(streamId, connection)
end;

function Pump:mouseEvent(posX, posY, isDown, isUp, button)
end;
function Pump:keyEvent(unicode, sym, modifier, isDown)
end;
function Pump:update(dt)
	if self.isClient then
		if self:getIsActiveForInput() and self.isMotorStarted then
			if InputBinding.hasEvent(InputBinding.Pump_SWITCH) then
				Pump:setIsTurnedOn(not Pump.isTurnedOn);
			end;
		end;
	end;
	
end;
function Pump:updateTick(dt)
		
		if self.count > 0 then
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

function Pump:setIsTurnedOn(state)
	Pump.isTurnedOn = state;
end;

function Pump:draw()
	if self.isClient then
		if Pump.isTurnedOn then
			g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_Pump"), self.typeDesc), InputBinding.Pump_SWITCH);
		else
			g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_Pump"), self.typeDesc), InputBinding.Pump_SWITCH);
		end;
	end;
end;
function Pump:attachImplement(implement)
end;
function Pump:detachImplement(implementIndex)
end;
function Pump:onEnter()
end;
function Pump:onLeave()
end;
