-- Special Things for Fire Deparment Vehicles
--
-- @author  Grisu118
-- @date  27/12/2013
-- @version 0.91
-- @Descripion: Readme you can find there: https://github.com/Grisu118/Scripts
-- @web: http://grisu118.ch or http://vertexdezign.de
-- Copyright (C) Grisu118, All Rights Reserved.
-- free for noncommerical-usage

--[[
<fuelIndicator>
		<indicator index="0>0" />
		<indicator index="0>1" />
		<indicator index="0>2" />
</fuelIndicator>

]]


FW_Additdional = {};

function FW_Additdional.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Motorized, specializations) and SpecializationUtil.hasSpecialization(Fillable, specializations);
end;
function FW_Additdional:load(xmlFile)	
	self.Mannschaft = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.Mannschaft#index"));
	self.drl = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.drl#index"));
	
	--Fuel Indicator
	self.count = 0;
	self.percent = 0;
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
	
		for j = 0, self.count, 1	do
			setVisibility(self.fuelIndicators[j], false);
		end;

	
	setVisibility(self.Mannschaft, false);
	setVisibility(self.drl, false);
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
	if self:getIsActive() then
		if self.isMotorStarted then
			setVisibility(self.drl, true);
		else
			setVisibility(self.drl, false);
		end;
		
		if self.count > 0 then
-- TODO Change Fuel Indicator
-- Attention Fuel Indicator only look to own filllevel not to fillevel of a trailer!
--			if self.fillLevel == 0 then
		end;
	end;
end;

function FW_Additdional:draw()
end;
function FW_Additdional:attachImplement(implement)
end;
function FW_Additdional:detachImplement(implementIndex)
end;
function FW_Additdional:onEnter()
			setVisibility(self.Mannschaft, true);
		if self.isMotorStarted then	
			setVisibility(self.drl, true);
		else
		    setVisibility(self.drl, false);
		end
end;
function FW_Additdional:onLeave()
			setVisibility(self.Mannschaft, false);
	    if self.isMotorStarted then
			setVisibility(self.drl, true);
		else			
			setVisibility(self.drl, false);
	     end
end;
