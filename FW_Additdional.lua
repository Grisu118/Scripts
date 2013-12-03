-- 
--
-- @author  Grisu118
-- @date  11/04/2013
-- @version 0.9
-- Copyright (C) Grisu118, All Rights Reserved.
-- free for noncommerical-usage


FW_Additdional = {};

function FW_Additdional.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Motorized, specializations);
end;
function FW_Additdional:load(xmlFile)	
	self.Mannschaft = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.Mannschaft#index"));
	self.drl = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.drl#index"));
	
	setVisibility(self.Mannschaft, false);
	setVisibility(self.drl, false);
end;

function FW_Additdional:delete()
end;
function FW_Additdional:readStream(streamId, connection)
end;
function FW_Additdional:writeStream(streamId, connection)
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