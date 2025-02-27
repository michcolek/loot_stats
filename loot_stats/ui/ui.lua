dofile('monstersLootOutfit')
dofile('showLootOnScreen')
dofile('menuOption')

function UI()
    local ui = {
        moduleButton = nil;
        mainWindow = nil;

        elements = {};

        listElements = {};

        actualVisibleTab = { tab = 0, info = 0 };

        -- Additional modules
        menuOption = MenuOption();
        monstersLootOutfit = MonstersLootOutfit();
        showLootOnScreen = ShowLootOnScreen();

        init = function(self)
            g_ui.loadUI('loot_icons')

            self.moduleButton = modules.client_topmenu.addRightGameToggleButton('lootStatsButton', tr('Loot Stats'), '/loot_stats/ui/img/icon', function() self:toggle() end)
            self.moduleButton:setOn(false)

            self.mainWindow = g_ui.displayUI('loot_stats')
            self.mainWindow:setVisible(false)

            self:loadElementsUI()
            self:setDefaultValuesToElementsUI()
            self:setOnChangeElements()

            self:connectStoreWithElements()

            -- Init additional modules
            self.menuOption:init()
            self.monstersLootOutfit:init()
            self.showLootOnScreen:init()
        end;

        terminate = function(self)
            self:clear()

            self:disconnectStoreFromElements()

            -- Terminate additional modules
            self.menuOption:terminate()
            self.monstersLootOutfit:terminate()
            self.showLootOnScreen:terminate()
        end;

        clear = function(self)
            -- Destroy created elements
            self:destroyListElements()

            self.mainWindow:destroy()
            self.mainWindow = nil
            self.moduleButton:destroy()
            self.moduleButton = nil

            self.elements = {}
        end;

        toggle = function(self)
            if self.moduleButton:isOn() then
                self.mainWindow:setVisible(false)
                self.moduleButton:setOn(false)
            else
                self.mainWindow:setVisible(true)
                self.moduleButton:setOn(true)

                self:refreshListElements()
            end
        end;

        onMiniWindowClose = function(self)
            self.moduleButton:setOn(false)
        end;

        loadElementsUI = function(self)
            self.elements.itemsPanel = self.mainWindow:recursiveGetChildById('itemsPanel')
            self.elements.monstersTab = self.mainWindow:recursiveGetChildById('monstersTab')
            self.elements.allLootTab = self.mainWindow:recursiveGetChildById('allLootTab')
            self.elements.panelCreatureView = self.mainWindow:recursiveGetChildById('panelCreatureView')
        end;

        setDefaultValuesToElementsUI = function(self)
            -- Open monster tab as default
            self.actualVisibleTab.tab = 'monster'
            self.elements.monstersTab:setOn(true)
        end;

        setOnChangeElements = function(self)
            self.elements.monstersTab.onMouseRelease = function(widget, mousePosition, mouseButton) self:whenClickMonstersTab(widget, mousePosition, mouseButton) end
            self.elements.allLootTab.onMouseRelease = function(widget, mousePosition, mouseButton) self:whenClickAllLootTab(widget, mousePosition, mouseButton) end
        end;

        -- Format data

        formatNumber = function(self, value, numbers, cutDigits)
            numbers = numbers or 0
            cutDigits = cutDigits or false

            if value - math.floor(value) == 0 then
                return value
            end

            local decimalPart = 0
            local intPart = 0

            if value > 1 then
                decimalPart = value - math.floor(value)
                intPart = math.floor(value)
            else
                decimalPart = value
            end

            local firstNonZeroPos = math.floor(math.log10(decimalPart)) + 1

            local numberOfPoints = 1
            if cutDigits then
                numberOfPoints = math.pow(10, numbers - math.floor(math.log10(value)) - 1)
            else
                numberOfPoints = math.pow(10, firstNonZeroPos * -1 + numbers)
            end

            local valuePow = decimalPart * numberOfPoints
            if valuePow - math.floor(valuePow) >= 0.5 then
                valuePow = math.ceil(valuePow)
            else
                valuePow = math.floor(valuePow)
            end

            return intPart + valuePow / numberOfPoints
        end;

        -- Monster view show/hide

        showMonsterView = function(self, creature, text)
            self.elements.panelCreatureView:setHeight(40)
            self.elements.panelCreatureView:setVisible(true)

            local ceatureView = self.elements.panelCreatureView:getChildById('creatureView')
            ceatureView:setCreature(creature)

            local creatureText = self.elements.panelCreatureView:getChildById('textCreatureView')
            creatureText:setText(text)
        end;

        hideMonsterView = function(self)
            self.elements.panelCreatureView:setHeight(0)
            self.elements.panelCreatureView:setVisible(false)
        end;

        -- On click actions

        changeWhenClickWidget = function(self, widget, mousePosition, mouseButton)
            if mouseButton == MouseLeftButton then
                self.elements.monstersTab:setOn(false)

                self:showMonsterView(widget:getChildById('creature'):getCreature(), widget:getChildById('text'):getText())

                local monsterName = ''
                for word in string.gmatch(widget:getChildById('text'):getText(), '([^'..'\n'..']+)') do
                    monsterName = word
                    break
                end

                if monsterName then
                    self:refreshLootItems(monsterName)
                end
            end
        end;

        whenClickMonstersTab = function(self, widget, mousePosition, mouseButton)
            if mouseButton == MouseLeftButton then
                self.elements.allLootTab:setOn(false)
                self.elements.monstersTab:setOn(true)
                self:refreshLootMonsters()
                self:hideMonsterView()
            end
        end;

        whenClickAllLootTab = function(self, widget, mousePosition, mouseButton)
            if mouseButton == MouseLeftButton then
                self.elements.monstersTab:setOn(false)
                self.elements.allLootTab:setOn(true)
                self:refreshLootItems('*all')
                self:hideMonsterView()
            end
        end;

        -- Add to UI

        destroyListElements = function(self)
            for a,b in pairs(self.listElements) do
                b:destroy()
                self.listElements[a] = nil
            end
        end;

        refreshLootItems = function(self, monsterName)
            local itemTable = {}
            if monsterName == '*all' then
                itemTable = store:returnAllLoot()
            else
                itemTable = store:returnMonsterLoot(monsterName)
            end

            self.actualVisibleTab.tab = 'loot'
            self.actualVisibleTab.info = monsterName

            local layout = self.elements.itemsPanel:getLayout()
            layout:disableUpdates()

            self:destroyListElements()
            self.elements.itemsPanel:destroyChildren()

            for a,b in pairs(itemTable) do
                self.listElements[a] = g_ui.createWidget('LootItemBox', self.elements.itemsPanel)

                local text = a .. '\n' .. 'Count: ' .. b.count

                if not b.plural then
                    local chanceToLoot = 0
                    if monsterName ~= '*all' then
                        chanceToLoot = b.count * 100 / store:returnMonsterCount(monsterName)
                    else
                        chanceToLoot = b.count * 100 / store:returnAllMonsterCount()
                    end
                    text = text .. '\n' .. 'Chance: ' .. self:formatNumber(chanceToLoot, 3, true) .. ' %'
                else
                    local chanceToLoot = 0
                    if monsterName ~= '*all' then
                        if b.count > store:returnMonsterCount(monsterName) then
                            chanceToLoot = b.count / store:returnMonsterCount(monsterName)
                            text = text .. '\n' .. 'Average: ' .. self:formatNumber(chanceToLoot, 3, true) .. ' / 1'
                        else
                            chanceToLoot = b.count * 100 / store:returnMonsterCount(monsterName)
                            text = text .. '\n' .. 'Chance: ' .. self:formatNumber(chanceToLoot, 3, true) .. ' %'
                        end
                    else
                        if b.count > store:returnAllMonsterCount() then
                            chanceToLoot = b.count / store:returnAllMonsterCount()
                            text = text .. '\n' .. 'Average: ' .. self:formatNumber(chanceToLoot, 3, true) .. ' / 1'
                        else
                            chanceToLoot = b.count * 100 / store:returnAllMonsterCount()
                            text = text .. '\n' .. 'Chance: ' .. self:formatNumber(chanceToLoot, 3, true) .. ' %'
                        end
                    end
                end

                self.listElements[a]:getChildById('text'):setText(text)
                 -- Wyszukujemy ID przedmiotu na podstawie nazwy 'a'
                 local serverId = nil
                 for id, item in pairs(items) do
                     if item.name == a then
                         serverId = id
                         break
                     end
                 end

                

                 local itemType = g_things.getItemType(serverId or 0) -- Jeśli serverId nie zostanie znaleziony, użyj 0

            
                

                local item = nil
              
                if itemType:getClientId() ~= 0 then
                    item = Item.create(itemType:getClientId())
                else
                    item = Item.create(3547)
                end

                if b.plural then
                    if b.count > 100 then
                        item:setCount(100)
                    else
                        item:setCount(b.count)
                    end
                end

                local itemWidget = self.listElements[a]:getChildById('item')
                itemWidget:setItem(item)
            end

            layout:enableUpdates()
            layout:update()
        end;
        refreshLootMonsters = function(self)
            local layout = self.elements.itemsPanel:getLayout()
            layout:disableUpdates()

            self:destroyListElements()
            self.elements.itemsPanel:destroyChildren()

            self.actualVisibleTab.tab = 'monster'
            self.actualVisibleTab.info = 0

            for a,b in pairs(store:returnAllMonsters()) do
                self.listElements[a] = g_ui.createWidget('LootMonsterBox', self.elements.itemsPanel)

                local text = a .. '\n' .. 'Count: ' .. b.count

                local chanceMonster = b.count * 100 / store:returnAllMonsterCount()
                text = text .. '\n' .. 'Chance: ' .. self:formatNumber(chanceMonster, 3, true) .. ' %'

                self.listElements[a]:getChildById('text'):setText(text)

                local uiCreature = Creature.create()
                uiCreature:setDirection(2)

                if b.outfit then
                    uiCreature:setOutfit(b.outfit)
                else
                    local noOutfit = { type = 160, feet = 114, addons = 0, legs = 114, auxType = 7399, head = 114, body = 114 }
                    uiCreature:setOutfit(noOutfit)
                end

                local itemWidget = self.listElements[a]:getChildById('creature')
                itemWidget:setCreature(uiCreature)

                -- On click action
                self.listElements[a].onMouseRelease = function(widget, mousePosition, mouseButton) self:changeWhenClickWidget(widget, mousePosition, mouseButton) end
            end

            layout:enableUpdates()
            layout:update()
        end;

        clearData = function(self)
            local yesCallback = function()
                local layout = self.elements.itemsPanel:getLayout()
                layout:disableUpdates()

                self:destroyListElements()
                self.elements.itemsPanel:destroyChildren()

                self.elements.allLootTab:setOn(false)
                self.elements.monstersTab:setOn(false)
                self:hideMonsterView()
                store.lootStatsTable = {}

                layout:enableUpdates()
                layout:update()

                saveOverWindow:destroy()
                saveOverWindow = nil
            end

            local noCallback = function()
                saveOverWindow:destroy()
                saveOverWindow = nil
            end

            if not saveOverWindow then
                saveOverWindow = displayGeneralBox(tr('Clear all values'), tr('Do you want clear all values?\nYou will lost all loot data!'), {
                    { text=tr('Yes'), callback = yesCallback },
                    { text=tr('No'), callback = noCallback },
                anchor=AnchorHorizontalCenter }, yesCallback, noCallback)
            end
        end;

        refreshListElements = function(self)
            if self.actualVisibleTab.tab == 'loot' then
                self:refreshLootItems(self.actualVisibleTab.info)
                if self.actualVisibleTab.info ~= '*all' then
                    local creatureText = self.elements.panelCreatureView:getChildById('textCreatureView')

                    local monster = store:returnAllMonsters()[self.actualVisibleTab.info]
                    local text = self.actualVisibleTab.info .. '\n' .. 'Count: ' .. monster.count

                    local chanceMonster = monster.count * 100 / store:returnAllMonsterCount()
                    text = text .. '\n' .. 'Chance: ' .. self:formatNumber(chanceMonster, 3, true) .. ' %'
                    creatureText:setText(text)
                end
            elseif self.actualVisibleTab.tab == 'monster' then
                self:refreshLootMonsters()
            end
        end;

        -- Connect

        connectStoreWithElements = function(self)
            store.onRefreshLootStatsTable.changeUI = function() self:refreshLootStatsTable() end
        end;

        disconnectStoreFromElements = function(self)
            store.onRefreshLootStatsTable.changeUI = nil
        end;

        refreshLootStatsTable = function(self)
            if self.mainWindow:isVisible() then
                self:refreshListElements()
            end
        end;
    }

    return ui
end
