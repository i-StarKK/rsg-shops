local Core = nil
local Framework = nil

local success = pcall(function()
    Core = exports['rsg-core']:GetCoreObject()
    Framework = 'rsg'
end)

if not success then
    success = pcall(function()
        Core = exports['vorp_core']:GetCore()
        Framework = 'vorp'
    end)
end

if not success then
    print('^1[ERROR] Neither RSG Core nor VORP Core could be loaded!^7')
    return
end

print('^2[INFO] Successfully loaded ' .. Framework .. ' framework^7')

local DiscordWebhook = 'YOUR_DISCORD_WEBHOOK_URL'

local function DebugPrint(message, type)
    if not Config.ShopkeeperSettings.debugMode then return end
    
    local color = '^7'
    if type == 'error' then
        color = '^1' -- Red
    elseif type == 'success' then
        color = '^2' -- Green
    elseif type == 'info' then
        color = '^3' -- Yellow
    elseif type == 'debug' then
        color = '^5' -- Blue
    end
    print(color .. '[SHOP] ' .. message .. '^7')
end

if Framework == 'rsg' then
    Core.Functions.CreateCallback('rsg-shop:server:getShopItems', function(source, cb, shopName)
        DebugPrint('Getting items for shop: ' .. shopName, 'info')
        
        local shopConfig = nil
        for _, shop in pairs(Config.Shops) do
            if shop.name == shopName then
                shopConfig = shop
                break
            end
        end
        
        if not shopConfig then
            DebugPrint('Shop not found: ' .. shopName, 'error')
            cb({}, Config.PaymentMethods)
            return
        end
        
        DebugPrint('Found shop items: ' .. json.encode(shopConfig.items), 'debug')
        cb(shopConfig.items, Config.PaymentMethods)
    end)
else
    Core.Callback.RegisterCallback('rsg-shop:server:getShopItems', function(source, cb, shopName)
        DebugPrint('Getting items for shop: ' .. shopName, 'info')
        
        local shopConfig = nil
        for _, shop in pairs(Config.Shops) do
            if shop.name == shopName then
                shopConfig = shop
                break
            end
        end
        
        if not shopConfig then
            DebugPrint('Shop not found: ' .. shopName, 'error')
            cb({}, Config.PaymentMethods)
            return
        end
        
        DebugPrint('Found shop items: ' .. json.encode(shopConfig.items), 'debug')
        cb(shopConfig.items, Config.PaymentMethods)
    end)
end

RegisterNetEvent('rsg-shop:server:processPurchase')
AddEventHandler('rsg-shop:server:processPurchase', function(purchaseData)
    local src = source
    local Player = nil
    
    if Framework == 'rsg' then
        Player = Core.Functions.GetPlayer(src)
    else
        Player = Core.getUser(src).getUsedCharacter
    end

    DebugPrint("Received purchase event for player [" .. src .. "]", 'debug')
    DebugPrint("Received purchase data: " .. json.encode(purchaseData), 'debug')

    if not Player then
        DebugPrint("Player object not found for source [" .. src .. "]", 'error')
        return
    end

    local items = purchaseData.items
    local paymentMethod = purchaseData.paymentMethod
    local shopName = purchaseData.shopName
    local totalAmount = 0
    local purchasedItemsList = ""

    if not shopName or shopName == "" then
        DebugPrint("Error: Shop name is missing in purchase data for player [" .. src .. "]. Aborting purchase.", 'error')
        if Framework == 'rsg' then
            TriggerClientEvent('RSGCore:Notify', src, 'Error: Shop information missing!', 'error')
        else
            TriggerClientEvent('vorp:TipRight', src, 'Error: Shop information missing!', 4000)
        end
        return
    end

    DebugPrint("Player [" .. src .. "] attempting to purchase from shop [" .. shopName .. "] using method [" .. paymentMethod .. "]", 'info')

    if items and #items > 0 then
        for _, item in ipairs(items) do
            local itemPrice = 0
            local foundConfigItem = false
            for _, shop in ipairs(Config.Shops) do
                if shop.name == shopName then
                    for _, configItem in ipairs(shop.items) do
                        if configItem.name == item.name then
                            itemPrice = configItem.price
                            foundConfigItem = true
                            break
                        end
                    end
                    break
                end
            end
            if not foundConfigItem then
                DebugPrint("Error: Item [" .. item.name .. "] not found in config for shop [" .. shopName .. "]! Aborting purchase.", 'error')
                if Framework == 'rsg' then
                    TriggerClientEvent('RSGCore:Notify', src, 'Error: Item not available in this shop!', 'error')
                else
                    TriggerClientEvent('vorp:TipRight', src, 'Error: Item not available in this shop!', 4000)
                end
                return
            end

            local itemTotal = itemPrice * item.quantity
            totalAmount = totalAmount + itemTotal
            purchasedItemsList = purchasedItemsList .. "- " .. item.label .. " (x" .. item.quantity .. "): $" .. itemTotal .. "\n"
            DebugPrint("Calculated total for " .. item.label .. " (x" .. item.quantity .. ") at $" .. itemPrice .. " each. Item total: $" .. itemTotal, 'debug')
        end
    else
        DebugPrint("Purchase data contains no items or invalid items list for player [" .. src .. "]. Aborting.", 'error')
        if Framework == 'rsg' then
            TriggerClientEvent('RSGCore:Notify', src, 'Error: No items in cart!', 'error')
        else
            TriggerClientEvent('vorp:TipRight', src, 'Error: No items in cart!', 4000)
        end
        return
    end

    DebugPrint("Calculated total purchase amount for player [" .. src .. "]: $" .. totalAmount, 'debug')

    local paymentSuccess = false
    local currentMoney = 0

    if paymentMethod == 'cash' then
        currentMoney = Player.PlayerData.money.cash
        DebugPrint("Player [" .. src .. "] current cash: $" .. currentMoney, 'debug')
        if currentMoney >= totalAmount then
            paymentSuccess = Player.Functions.RemoveMoney('cash', totalAmount, "shop-purchase")
            DebugPrint("Attempted to remove $" .. totalAmount .. " cash. Success: " .. tostring(paymentSuccess), 'debug')
        else
            DebugPrint("Player [" .. src .. "] does not have enough cash ( $" .. currentMoney .. ") for purchase ( $" .. totalAmount .. ").", 'error')
            if Framework == 'rsg' then
                TriggerClientEvent('RSGCore:Notify', src, 'Not enough cash!', 'error')
            else
                TriggerClientEvent('vorp:TipRight', src, 'Not enough cash!', 4000)
            end
        end
    elseif paymentMethod == 'bank' then
        currentMoney = Player.PlayerData.money.bank
        DebugPrint("Player [" .. src .. "] current bank balance: $" .. currentMoney, 'debug')
        if currentMoney >= totalAmount then
            paymentSuccess = Player.Functions.RemoveMoney('bank', totalAmount, "shop-purchase")
             DebugPrint("Attempted to remove $" .. totalAmount .. " bank. Success: " .. tostring(paymentSuccess), 'debug')
        else
            DebugPrint("Player [" .. src .. "] does not have enough bank balance ( $" .. currentMoney .. ") for purchase ( $" .. totalAmount .. ").", 'error')
            if Framework == 'rsg' then
                TriggerClientEvent('RSGCore:Notify', src, 'Not enough bank balance!', 'error')
            else
                TriggerClientEvent('vorp:TipRight', src, 'Not enough bank balance!', 4000)
            end
        end
    else
        DebugPrint("Player [" .. src .. "] used invalid payment method: " .. paymentMethod, 'error')
        if Framework == 'rsg' then
            TriggerClientEvent('RSGCore:Notify', src, 'Invalid payment method!', 'error')
        else
            TriggerClientEvent('vorp:TipRight', src, 'Invalid payment method!', 4000)
        end
    end

    if paymentSuccess then
        DebugPrint("Payment successful for player [" .. src .. "]. Adding items.", 'debug')
        for _, item in ipairs(items) do
            Player.Functions.AddItem(item.name, item.quantity)
            TriggerClientEvent('inventory:client:ItemBox', src, Core.Shared.Items[item.name], 'add')
            DebugPrint("Added item [" .. item.name .. "] with quantity [" .. item.quantity .. "] for player [" .. src .. "]", 'debug')
        end

        DebugPrint("Checking Discord webhook URL.", 'debug')
        DebugPrint("DiscordWebhook variable value: " .. DiscordWebhook, 'debug')
        if DiscordWebhook ~= 'YOUR_DISCORD_WEBHOOK_URL' then
            local playerName = "Unknown Player"
            if Player.PlayerData and Player.PlayerData.charinfo then
                playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            end

            local embed = {
                {
                    title = "New Shop Purchase",
                    description = "A player has made a purchase in a shop.",
                    type = "rich",
                    color = 65280,
                    fields = {
                        { name = "Player Name", value = playerName, inline = true },
                        { name = "Player ID", value = src, inline = true },
                        { name = "Shop Name", value = shopName, inline = true },
                        { name = "Payment Method", value = paymentMethod, inline = true },
                        { name = "Total Amount", value = "$" .. totalAmount, inline = true },
                        { name = "Purchased Items", value = purchasedItemsList, inline = false }
                    },
                    footer = {
                        text = os.date("%Y-%m-%d %H:%M:%S"),
                    },
                }
            }

            PerformHttpRequest(DiscordWebhook, function(err, text, headers) 
                if err == 200 then
                    DebugPrint("Discord webhook sent successfully for player [" .. src .. "].", 'success')
                else
                    DebugPrint("Error sending Discord webhook for player [" .. src .. "]. Error code: " .. tostring(err) .. ", Response: " .. tostring(text), 'error')
                end
            end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
        else
            DebugPrint("Discord webhook URL not configured! Purchase not logged for player [" .. src .. "].", 'info')
        end

        -- Update notification calls based on framework
        if Framework == 'rsg' then
            TriggerClientEvent('RSGCore:Notify', src, 'Purchase successful!', 'success')
        else
            TriggerClientEvent('vorp:TipRight', src, 'Purchase successful!', 4000)
        end

    else
        DebugPrint("Payment failed for player [" .. src .. "]. Items not added and webhook not sent.", 'error')
    end

end)
