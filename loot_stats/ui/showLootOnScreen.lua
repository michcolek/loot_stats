

function ShowLootOnScreen()
    local showLootOnScreen = {
        mainScreenTab = {};
        cacheLastTime = { t = 0, i = 1 };
        lootIconOnScreen = {};

        init = function(self)
            self:connectStoreWithElements()
        end;

        terminate = function(self)
            self:disconnectStoreFromElements()

            self:destroy()
        end;

       

        add = function(self, tab)
            for i = 1, store:getAmountLootOnScreen() do
                self.mainScreenTab[i] = {}
                if i + 1 <= store:getAmountLootOnScreen() then
                    self.mainScreenTab[i] = self.mainScreenTab[i + 1]
                else
                    if tab ~= nil then
                        self.mainScreenTab[i].loot = tab
                        if g_clock.millis() == self.cacheLastTime.t then
                            self.mainScreenTab[i].id = g_clock.millis() * 100 + self.cacheLastTime.i
                            self.cacheLastTime.i = self.cacheLastTime.i + 1

                            -- Delete value after x time
                            self:scheduleDisappear(self.mainScreenTab[i].id)
                        else
                            self.mainScreenTab[i].id = g_clock.millis()
                            self.cacheLastTime.t = g_clock.millis()
                            self.cacheLastTime.i = 1

                            -- Delete value after x time
                            self:scheduleDisappear(self.mainScreenTab[i].id)
                        end
                    else
                        self.mainScreenTab[i] = nil
                    end
                end
            end

            if tab == nil and table.size(self.mainScreenTab) then
                self.mainScreenTab[#self.mainScreenTab] = nil
            end

            self:refresh()
        end;

        scheduleDisappear = function(self, id)
            scheduleEvent(function()
                for a,b in pairs(self.mainScreenTab) do
                    if self.mainScreenTab[a].id == id then
                        self.mainScreenTab[a] = nil
                        self:add(nil)
                        self:refresh()
                        break
                    end
                end
            end, store:getDelayTimeLootOnScreen())
        end;

        refresh = function(self)
            self:destroy()
        
           
    local screenWidth = self:getMapPanel():getWidth()
    local lootIconsWidth = 32 * table.size(self.mainScreenTab) -- Zakładając, że każda ikona ma szerokość 32 px
    local actualX = (screenWidth - lootIconsWidth) / 2 -- Centrowanie ikon na górze ekranu
    local actualY = 0

    if self:getTopMenu():isVisible() then
        actualY = self:getTopMenu():getHeight()
    end
            for a, b in pairs(self.mainScreenTab) do
                if actualY <= self:getMapPanel():getHeight() - 32 then
                    for c, d in pairs(b.loot) do
                        print(c)
                       
                        
                        
                        if actualX <= self:getMapPanel():getWidth() - 32 then
                            self.lootIconOnScreen[c..a] = g_ui.createWidget("LootIcon", self:getMapPanel())
        
                            -- Wyszukujemy ID przedmiotu na podstawie nazwy 'c'
                            local serverId = nil
                            for id, item in pairs(items) do
                                if item.name == c then
                                    serverId = id
                                    break
                                end
                            end
        
                            if serverId then
                                print("Znaleziono przedmiot o ID:", serverId)
                            else
                                print("Przedmiot nie został znaleziony.")
                            end
        
                            local itemType = g_things.getItemType(serverId or 0) -- Jeśli serverId nie zostanie znaleziony, użyj 0
        
                            if itemType and itemType ~= m_nullItemType then
                                print(" z Client ID: " .. itemType:getClientId())
                                self.lootIconOnScreen[c .. a]:setItemId(itemType:getClientId())
                            else
                                print("Item not found, using default ID")
                                self.lootIconOnScreen[c .. a]:setItemId(3547)
                            end
        
                            self.lootIconOnScreen[c .. a]:setVirtual(true)
                            self.lootIconOnScreen[c .. a]:setX(actualX + self:getMapPanel():getX())
                            actualX = actualX + 32
                            self.lootIconOnScreen[c .. a]:setY(actualY)
                            if d.count > 1 then
                                self.lootIconOnScreen[c .. a]:setItemCount(d.count)
                            end
                        end
                    end
                end
        
                actualX = 0
                actualY = actualY + 32
            end
        end;


        destroy = function(self)
            for a,b in pairs(self.lootIconOnScreen) do
                self.lootIconOnScreen[a]:destroy()
                self.lootIconOnScreen[a] = nil
            end
        end;

        getMapPanel = function(self)
            return modules.game_interface.getMapPanel()
        end;

        getTopMenu = function(self)
            return modules.client_topmenu.getTopMenu()
        end;

        -- Connect

        connectStoreWithElements = function(self)
            store.onAddLootLog.showLootOnScreen = function(lootData) self:addLootLog(lootData) end
        end;

        disconnectStoreFromElements = function(self)
            store.onAddLootLog.showLootOnScreen = nil
        end;

        addLootLog = function(self, lootData)
            if store:getShowLootOnScreen() then
                self:add(lootData)
            end
        end;
    }

    return showLootOnScreen
end
