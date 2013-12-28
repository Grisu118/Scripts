  -- waterCannon
  -- Class for all waterCannons
  --
  -- @author  Stefan Geiger
  -- @date  24/02/08
  --
  -- @Edited for Fire Trucks, Grisu118
  -- @version v0.8
  -- @date 28.12.13
  -- @Descripion: Readme you can find there: https://github.com/Grisu118/Scripts
  -- @web: http://grisu118.ch or http://vertexdezign.de
  --
  -- Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.
  
  source("dataS/scripts/vehicles/specializations/SetTurnedOnEvent.lua");
  source("dataS/scripts/vehicles/specializations/SprayerAreaEvent.lua");
  source("dataS/scripts/vehicles/specializations/SprayerSetIsFillingEvent.lua");
  waterCannon = {};
  
  
  waterCannon.SPRAYTYPE_UNKNOWN = 0;
  waterCannon.NUM_SPRAYTYPES = 0;
  
  waterCannon.sprayTypes = {};
  waterCannon.sprayTypeIndexToDesc = {};
  
  waterCannon.sprayTypeToFillType = {};
  waterCannon.fillTypeToSprayType = {};
  
  function waterCannon.registerSprayType(name, pricePerLiter, litersPerSqmPerSecond, hudOverlayFilename)
      local key = "SPRAYTYPE_"..string.upper(name);
      if waterCannon[key] == nil then
          waterCannon.NUM_SPRAYTYPES = waterCannon.NUM_SPRAYTYPES+1;
          waterCannon[key] = waterCannon.NUM_SPRAYTYPES;
  
          local desc = {name = name, index = waterCannon.NUM_SPRAYTYPES};
          desc.pricePerLiter = pricePerLiter;
          desc.litersPerSqmPerSecond = litersPerSqmPerSecond;
          desc.hudOverlayFilename = hudOverlayFilename;
  
  
          waterCannon.sprayTypes[name] = desc;
          waterCannon.sprayTypeIndexToDesc[waterCannon.NUM_SPRAYTYPES] = desc;
  
          local fillType = Fillable.registerFillType(name)
          waterCannon.sprayTypeToFillType[waterCannon.NUM_SPRAYTYPES] = fillType;
          waterCannon.fillTypeToSprayType[fillType] = waterCannon.NUM_SPRAYTYPES;
      end;
  end;
  
  waterCannon.registerSprayType("fertilizer", 0.3, 0.5, "");
  waterCannon.registerSprayType("manure", 0.01, 0.5, "");
  waterCannon.registerSprayType("liquidManure", 0.01, 0.5, "");
  
function waterCannon.prerequisitesPresent(specializations)
      return SpecializationUtil.hasSpecialization(Fillable, specializations);
  end;
  
  function waterCannon:load(xmlFile)
  
      assert(self.setIsTurnedOn == nil, "waterCannon needs to be the first specialization which implements setIsTurnedOn");
      self.setIsTurnedOn = waterCannon.setIsTurnedOn;
      self.getIsTurnedOnAllowed = waterCannon.getIsTurnedOnAllowed;
  
      assert(self.setIswaterCannonFilling == nil, "waterCannon needs to be the first specialization which implements setIswaterCannonFilling");
      self.setIswaterCannonFilling = waterCannon.setIswaterCannonFilling;
      self.addwaterCannonFillTrigger = waterCannon.addwaterCannonFillTrigger;
      self.removewaterCannonFillTrigger = waterCannon.removewaterCannonFillTrigger;
  
      self.fillLitersPerSecond = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillLitersPerSecond"), 500);
      self.iswaterCannonFilling = false;
  
      self.sprayLitersPerSecond = {};
      local i=0;
      while true do
          local key = string.format("vehicle.sprayUsages.sprayUsage(%d)", i);
          if not hasXMLProperty(xmlFile, key) then
              break;
          end;
          local fillType = getXMLString(xmlFile, key.. "#fillType");
          local litersPerSecond = getXMLFloat(xmlFile, key.. "#litersPerSecond");
          if fillType ~= nil and litersPerSecond ~= nil then
              local fillTypeInt = Fillable.fillTypeNameToInt[fillType];
              if fillTypeInt ~= nil then
                  self.sprayLitersPerSecond[fillTypeInt] = litersPerSecond;
                  if self.defaultSprayLitersPerSecond == nil then
                      self.defaultSprayLitersPerSecond = litersPerSecond;
                  end;
              else
                  print("Warning: Invalid spray usage fill type '"..fillType.."' in '" .. self.configFileName.. "'");
              end;
          end;
          i = i+1;
      end;
      if self.defaultSprayLitersPerSecond == nil then
          print("Warning: No spray usage specified for '" .. self.configFileName.. "'. This waterCannon will not use any spray.");
          self.defaultSprayLitersPerSecond = 0;
      end;
  
      self.sprayValves = {};
  
      if self.isClient then
          local psFile = getXMLString(xmlFile, "vehicle.sprayParticleSystem#file");
          if psFile ~= nil then
           local i=0;
              while true do
                  local baseName = string.format("vehicle.sprayValves.sprayValve(%d)", i);
                  local node = getXMLString(xmlFile, baseName.. "#index");
                  if node == nil then
                      break;
                  end;
                  node = Utils.indexToObject(self.components, node);
                  if node ~= nil then
                      local sprayValve = {};
                      sprayValve.particleSystems = {};
                      Utils.loadParticleSystem(xmlFile, sprayValve.particleSystems, "vehicle.sprayParticleSystem", node, false, nil, self.baseDirectory);
                      table.insert(self.sprayValves, sprayValve);
                  end;
                  i = i+1;
              end;
          end;
  
          local spraySound = getXMLString(xmlFile, "vehicle.spraySound#file");
          if spraySound ~= nil and spraySound ~= "" then
              spraySound = Utils.getFilename(spraySound, self.baseDirectory);
              self.spraySound = createSample("spraySound");
              self.spraySoundEnabled = false;
              loadSample(self.spraySound, spraySound, false);
              self.spraySoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.spraySound#pitchOffset"), 1);
              self.spraySoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.spraySound#volume"), 1);
          end;
      end;
  
      self.waterCannonFillTriggers = {};
      self.waterCannonFillActivatable = waterCannonFillActivatable:new(self);
  
      self.isTurnedOn = false;
      self.speedViolationMaxTime = 1000;
      self.speedViolationTimer = self.speedViolationMaxTime;
  end;
  
  function waterCannon:delete()
  
      g_currentMission:removeActivatableObject(self.waterCannonFillActivatable);
  
      for k,sprayValve in pairs(self.sprayValves) do
          Utils.deleteParticleSystem(sprayValve.particleSystems);
      end;
  
      if self.spraySound ~= nil then
          delete(self.spraySound);
      end;
  end;
  
 function waterCannon:readStream(streamId, connection)
      local turnedOn = streamReadBool(streamId);
      local iswaterCannonFilling = streamReadBool(streamId);
      self:setIsTurnedOn(turnedOn, true);
      self:setIswaterCannonFilling(iswaterCannonFilling, true);
  end;
  
  function waterCannon:writeStream(streamId, connection)
      streamWriteBool(streamId, self.isTurnedOn);
      streamWriteBool(streamId, self.iswaterCannonFilling);
  end;
  
  function waterCannon:readUpdateStream(streamId, timestamp, connection)
  end;
  
  function waterCannon:writeUpdateStream(streamId, connection, dirtyMask)
  end;
  
  function waterCannon:mouseEvent(posX, posY, isDown, isUp, button)
  end;
  
  function waterCannon:keyEvent(unicode, sym, modifier, isDown)
  end;
  
  function waterCannon:update(dt)
  
      if self.isClient then
          if self:getIsActiveForInput() then
              if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
                  self:setIsTurnedOn(not self.isTurnedOn);
              end;
          end;
      end;
  
  end;
  
  function waterCannon:updateTick(dt)
		if self.isTurnedOn then
			
			if self:doCheckSpeedLimit() and self.lastSpeed*3600 > 90 then
                  self.speedViolationTimer = self.speedViolationTimer - dt;
				  		
              else
                  self.speedViolationTimer = self.speedViolationMaxTime;
				  stopsoundGrisu = false;
            end;
			
			if self.isServer then
			 if self.speedViolationTimer > 0 then
				local litersPerSecond = self.sprayLitersPerSecond[self.currentFillType];
				if litersPerSecond == nil then
					litersPerSecond = self.defaultSprayLitersPerSecond;
				end;
				local usage = litersPerSecond * dt*0.001;
				
				if not self.capacity == 0 or not self:getIsHired() then
					if self.fillLevel > 0 then
                              hasSpray = true;
                              self:setFillLevel(self.fillLevel - usage, self.currentFillType);
                    end;
				end;
			 end;
			end;
		end;
  
      if self:getIsActive() then
          if self.isTurnedOn then
              self.lastSprayingArea = 0;
  
              
  
              if self.isServer then
               if self.speedViolationTimer > 0 then
--                      local litersPerSecond = self.sprayLitersPerSecond[self.currentFillType];
--                      if litersPerSecond == nil then
--                         litersPerSecond = self.defaultSprayLitersPerSecond;
--                      end
--                      local usage = litersPerSecond * dt*0.001;
  
                      local hasSpray = false;
  
                      if self.capacity == 0 or self:getIsHired() then
                          hasSpray = true;
                          local sprayType = waterCannon.fillTypeToSprayType[self.currentFillType];
                          if sprayType ~= nil then
                              local sprayTypeDesc = waterCannon.sprayTypeIndexToDesc[sprayType];
                              local delta = usage*sprayTypeDesc.pricePerLiter
                              g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + delta;
                              g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + delta;
  
                              g_currentMission:addSharedMoney(-delta);
  
                              -- TODO update spray stats
                              --[[g_currentMission.missionStats.sprayUsageTotal = g_currentMission.missionStats.sprayUsageTotal + usage;
                              g_currentMission.missionStats.sprayUsageSession = g_currentMission.missionStats.sprayUsageSession + usage;]]
                          end;
--                      else
--                          if self.fillLevel > 0 then
--                              hasSpray = true;
--                              self:setFillLevel(self.fillLevel - usage, self.currentFillType);
--                          end;
                      end;
  
                      if hasSpray then
                          local cuttingAreasSend = {};
                          for k,cuttingArea in pairs(self.cuttingAreas) do
                              if self:getIsAreaActive(cuttingArea) then
                                  local x,y,z = getWorldTranslation(cuttingArea.start);
                                  local x1,y1,z1 = getWorldTranslation(cuttingArea.width);
                                  local x2,y2,z2 = getWorldTranslation(cuttingArea.height);
  
                                  local sqm = math.abs((z1-z)*(x2-x) - (x1-x)*(z2-z)); -- this is the cross product with y=0
  
                                  --Utils.updateSprayArea(x, z, x1, z1, x2, z2);
  
                                  self.lastSprayingArea = self.lastSprayingArea + sqm;
  
                                  table.insert(cuttingAreasSend, {x,z,x1,z1,x2,z2});
                              end;
                          end;
                          if (table.getn(cuttingAreasSend) > 0) then
                              waterCannonAreaEvent.runLocally(cuttingAreasSend);
                           g_server:broadcastEvent(waterCannonAreaEvent:new(cuttingAreasSend));
                          end;
                      end;
                  end;
              end;
  
              if self.isClient then
                  if not self.spraySoundEnabled and self:getIsActiveForSound() then
					  playSample(self.spraySound, 0, self.spraySoundVolume, 0);
                      setSamplePitch(self.spraySound, self.spraySoundPitchOffset);
                      self.spraySoundEnabled = true;
					  
                  end;
              end;
  
              if self.fillLevel <= 0 and self.capacity ~= 0 then
                  self:setIsTurnedOn(false, true);
              end;
          else
              self.speedViolationTimer = self.speedViolationMaxTime;
          end;
      end;
  
      if self.iswaterCannonFilling and self.isServer then
          local disableFilling = false;
          if self:allowFillType(self.waterCannonFillingFillType, false) then
              local oldFillLevel = self.fillLevel;
  
              local delta = self.fillLitersPerSecond*dt*0.001;
  
              local silo = g_currentMission:getSiloAmount(self.waterCannonFillingFillType);
              if self.waterCannonFillingIsSiloTrigger then
                  if silo <= 0 then
                      disableFilling = true;
                  end;
                  delta = math.min(delta, silo);
              end;
  
              self:setFillLevel(self.fillLevel + delta, self.waterCannonFillingFillType, true);
              local delta = self.fillLevel - oldFillLevel;
              if delta > 0 then
                  if self.waterCannonFillingIsSiloTrigger then
                      g_currentMission:setSiloAmount(self.waterCannonFillingFillType, silo - delta);
                  else
                      local sprayType = waterCannon.fillTypeToSprayType[self.waterCannonFillingFillType];
                      if sprayType ~= nil then
                          local sprayTypeDesc = waterCannon.sprayTypeIndexToDesc[sprayType]
  
                          local price = delta*sprayTypeDesc.pricePerLiter;
                          g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price;
                          g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price;
                          g_currentMission:addSharedMoney(-price);
                      end;
                  end;
              elseif self.fillLevel == self.capacity then
                  disableFilling = true;
              end;
          else
              disableFilling = true;
          end;
          if disableFilling then
              self:setIswaterCannonFilling(false);
          end;
      end;
  end;
  
  function waterCannon:draw()
  
      if self.isClient then
          if self.fillLevel <= 0 and self.capacity ~= 0 then
              --g_currentMission:addExtraPrintText(g_i18n:getText("FirstFillTheTool"));
          end;
  
          if self.isTurnedOn then
				
				g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA);
          else
              g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA);
          end;
  
          --[[if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
              g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", tBinding.getKeyNamesOfDigitalAction(InputBinding.SPEED_LEVEL2)), 0.07+0.022, 0.019+0.029);
         end;]]
      end;
  end;
  
  function waterCannon:onDetach()
      if self.deactivateOnDetach then
          waterCannon.onDeactivate(self);
      else
          waterCannon.onDeactivateSounds(self);
      end;
  end;
  
  function waterCannon:onLeave()
      if self.deactivateOnLeave then
          waterCannon.onDeactivate(self);
      else
          waterCannon.onDeactivateSounds(self);
      end;
  end;
  function waterCannon:onDeactivate()
      self.speedViolationTimer = self.speedViolationMaxTime;
     -- self:setIsTurnedOn(false, true)
      waterCannon.onDeactivateSounds(self);
  end;
  
  function waterCannon:onDeactivateSounds()
      if self.spraySoundEnabled then
          stopSample(self.spraySound);
          self.spraySoundEnabled = false;
      end;
  end;
  
  function waterCannon:getIsTurnedOnAllowed(isTurnedOn)
      if not isTurnedOn or self.fillLevel > 0 or self.capacity == 0 then
          return true;
      end;
  end;
  
  function waterCannon:setIsTurnedOn(isTurnedOn, noEventSend)
      if isTurnedOn ~= self.isTurnedOn then
          if self:getIsTurnedOnAllowed(isTurnedOn) then
              SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)
  
              self.isTurnedOn = isTurnedOn;
              if self.isClient then
                  for k,sprayValve in pairs(self.sprayValves) do
                      Utils.setEmittingState(sprayValve.particleSystems, self.isTurnedOn);
                  end;
  
                  if not self.isTurnedOn and self.spraySoundEnabled then
                      stopSample(self.spraySound);
                      self.spraySoundEnabled = false;
                  end;
              end;
              self.speedViolationTimer = self.speedViolationMaxTime;
          end;
      end;
  end;
  
  function waterCannon:setIswaterCannonFilling(isFilling, fillType, isSiloTrigger, noEventSend)
      SprayerSetIsFillingEvent.sendEvent(self, isFilling, fillType, isSiloTrigger, noEventSend)
      if self.iswaterCannonFilling ~= isFilling then
          self.iswaterCannonFilling = isFilling;
          self.waterCannonFillingFillType = fillType;
          self.waterCannonFillingIsSiloTrigger = isSiloTrigger;
      end;
  end;
  
function waterCannon:addwaterCannonFillTrigger(trigger)
      if table.getn(self.waterCannonFillTriggers) == 0 then
          g_currentMission:addActivatableObject(self.waterCannonFillActivatable);
      end;
      table.insert(self.waterCannonFillTriggers, trigger);
  end;
  
  function waterCannon:removewaterCannonFillTrigger(trigger)
      for i=1, table.getn(self.waterCannonFillTriggers) do
          if self.waterCannonFillTriggers[i] == trigger then
              table.remove(self.waterCannonFillTriggers, i);
              break;
          end;
      end;
      if table.getn(self.waterCannonFillTriggers) == 0 then
          if self.isServer then
              self:setIswaterCannonFilling(false);
          end;
          g_currentMission:removeActivatableObject(self.waterCannonFillActivatable);
      end;
  end;
  
  waterCannonFillActivatable = {}
  local waterCannonFillActivatable_mt = Class(waterCannonFillActivatable);
  
  function waterCannonFillActivatable:new(waterCannon)
      local self = {};
      setmetatable(self, waterCannonFillActivatable_mt);
  
      self.waterCannon = waterCannon;
      self.activateText = "unknown";
  
      self.currentTrigger = nil;
  
      return self;
  end;
  
  
  function waterCannonFillActivatable:getIsActivatable()
      self.currentTrigger = nil;
      if not self.waterCannon:getIsActiveForInput() or self.waterCannon.fillLevel == self.waterCannon.capacity then
          return false;
      end;
      -- find the first trigger which is activable
      for i=1, table.getn(self.waterCannon.waterCannonFillTriggers) do
          local trigger = self.waterCannon.waterCannonFillTriggers[i];
          if trigger:getIsActivatable(self.waterCannon) then
              self.currentTrigger = trigger;
              self:updateActivateText();
              return true;
          end;
      end;
      return false;
  end;
  
  function waterCannonFillActivatable:onActivateObject()
      self.waterCannon:setIswaterCannonFilling(not self.waterCannon.iswaterCannonFilling, self.currentTrigger.fillType, self.currentTrigger.isSiloTrigger);
      self:updateActivateText();
      g_currentMission:addActivatableObject(self);
  end;
  
  function waterCannonFillActivatable:drawActivate()
      -- TODO draw icon
  end;
  
  function waterCannonFillActivatable:updateActivateText()
      if self.waterCannon.iswaterCannonFilling then
          self.activateText = string.format(g_i18n:getText("stop_refill_OBJECT"), self.waterCannon.typeDesc);
      else
          self.activateText = string.format(g_i18n:getText("refill_OBJECT"), self.waterCannon.typeDesc);
      end;
   end;