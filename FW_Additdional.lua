-- Special Things for Fire Deparment Vehicles
--
-- @author  Grisu118
-- @date  28/12/2013
-- @version 1.0
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

<drl index="0>15|12" /> <!-- Day Drive light, is on when motor is started-->

<crew index="0>16|1" /> <!-- Crew, is visible when you are in the car -->

]]


FW_Additdional = {};

function FW_Additdional.prerequisitesPresent(specializations)
	if not SpecializationUtil.hasSpecialization(Motorized, specializations) then
		print("Warning: Specialization FW_Additdional needs the specialization Motorized.");
	end;
	if not SpecializationUtil.hasSpecialization(Fillable, specializations) then
		print("Warning: Specialization FW_Additdional needs the specialization Fillable.");
	end;

	return SpecializationUtil.hasSpecialization(Motorized, specializations) and SpecializationUtil.hasSpecialization(Fillable, specializations);
end;
function FW_Additdional:load(xmlFile)
	--crew
	self.crew = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.crew#index"));
	setVisibility(self.crew, false);
	
	--drl (day Drive Light)
	self.drl = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.drl#index"));
	setVisibility(self.drl, false);
	
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
	
end;

function FW_Additdional:delete()
end;
function FW_Additdional:readStream(streamId, connection)
end;
function FW_Additdional:writeStream(streamId, connection)
end;

function FW_Additdional:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	local fillLevel = getXMLFloat(xmlFile, key .. "#fillLevel");
	if fillLevel ~= nil then
-- TODO Set Fuel indicator from xml while Loading
	end;
	
	return BaseMission.VEHICLE_LOAD_OK;
end;

function FW_Additdional:mouseEvent(posX, posY, isDown, isUp, button)
end;
function FW_Additdional:keyEvent(unicode, sym, modifier, isDown)
end;
function FW_Additdional:update(dt)
end;
function FW_Additdional:updateTick(dt)
--	if self:getIsActive() then
		if self.isMotorStarted then
			setVisibility(self.drl, true);
		else
			setVisibility(self.drl, false);
		end;
		
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
--	end;
end;

function FW_Additdional:draw()
end;
function FW_Additdional:attachImplement(implement)
end;
function FW_Additdional:detachImplement(implementIndex)
end;
function FW_Additdional:onEnter()
			setVisibility(self.crew, true);
		if self.isMotorStarted then	
			setVisibility(self.drl, true);
		else
		    setVisibility(self.drl, false);
		end
end;
function FW_Additdional:onLeave()
			setVisibility(self.crew, false);
	    if self.isMotorStarted then
			setVisibility(self.drl, true);
		else			
			setVisibility(self.drl, false);
	     end
end;
