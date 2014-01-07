-- Fügt stündlich einen Betrag auf das Konto des Spielers hinzu.
--
-- @author  Grisu118
-- @date  03/12/2013
-- @version 1.0
-- @Descripion: Readme you can find there: https://github.com/Grisu118/Scripts
-- @web: http://grisu118.ch or http://vertexdezign.de
-- Copyright (C) Grisu118, All Rights Reserved.
-- free for noncommerical-usage


AddMoney = {};

function AddMoney.prerequisitesPresent(specializations)
	print "AddMoney by Grisu118 loaded, special thanks to Sven777b";
    return true;
end;

function AddMoney:load(xmlFile)
	self.incomePerHour = 0;
	local difficultyMultiplier = 2 ^ (3 - g_currentMission.missionStats.difficulty); --4 2 1
	self.incomePerHour = difficultyMultiplier * Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.incomePerHour"), 100);
	
	g_currentMission.environment:addHourChangeListener(self);
	self.hourChanged = SpecializationUtil.callSpecializationsFunction("hourChanged")
	
	
	
	
end;

function AddMoney:delete()
	g_currentMission.environment:removeHourChangeListener(self);
end;

function AddMoney:getSaveAttributesAndNodes(nodeIdent)
	
end;

function AddMoney:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	
end;

function AddMoney:readStream(streamId, connection)
	
end;

function AddMoney:writeStream(streamId, connection)
	
end;

function AddMoney:mouseEvent(posX, posY, isDown, isUp, button)
end;

function AddMoney:keyEvent(unicode, sym, modifier, isDown)
end;

function AddMoney:update(dt)
end;

function AddMoney:updateTick(dt)
	
end;

function AddMoney:hourChanged()
       if self.isServer then
           g_currentMission:addSharedMoney(self.incomePerHour, "other");
       end;
end;

function AddMoney:draw()	
end;
