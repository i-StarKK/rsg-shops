local Core = nil
local Framework = nil
local currentShop = nil
local cart = {}
local shopPeds = {}
local prompts = {}
local deadShopkeepers = {}
local isResourceStopping = false
local isInitialized = false
local activeShopkeepers = {}
local shopBlips = {}

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

local function DebugPrint(message, type)
    if not Config.ShopkeeperSettings.debugMode then return end
    
    local color = '^7'
    if type == 'error' then
        color = '^1'
    elseif type == 'success' then
        color = '^2'
    elseif type == 'info' then
        color = '^3'
    elseif type == 'debug' then
        color = '^5'
    end
    print(color .. '[SHOP] ' .. message .. '^7')
end

local function CleanupShopkeepers()
    DebugPrint("Cleaning up all shopkeepers...", 'info')
        for _, blip in pairs(shopBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    shopBlips = {}
    for _, ped in pairs(shopPeds) do
        if DoesEntityExist(ped) and IsEntityAPed(ped) then
            DeletePed(ped)
        end
    end
    shopPeds = {}
    deadShopkeepers = {}
    prompts = {}
    activeShopkeepers = {}
    isInitialized = false
    
    DebugPrint("Cleanup completed", 'success')
end

local function IsShopkeeperActive(shopName)
    return activeShopkeepers[shopName] == true
end

local function SetShopkeeperActive(shopName, active)
    activeShopkeepers[shopName] = active
end

local function CreateShopkeeper(model, coords, shopData)
    if isResourceStopping then return nil end
    
    if IsShopkeeperActive(shopData.name) then
        DebugPrint("Shopkeeper already exists for shop: " .. shopData.name, 'error')
        return nil
    end
    local existingPed = GetClosestPed(coords.x, coords.y, coords.z, 1.0, true, true, false, false, -1)
    if existingPed ~= 0 and IsEntityAPed(existingPed) then
        DebugPrint("Found existing ped at location, removing...", 'info')
        DeletePed(existingPed)
        Wait(100)
    end
    
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(1)
    end
    local ped = CreatePed(modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true, true, true)
    if not DoesEntityExist(ped) then
        DebugPrint("Failed to create shopkeeper", 'error')
        return nil
    end

    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    local randomAnim = Config.ShopkeeperAnimations[math.random(1, #Config.ShopkeeperAnimations)]
    TaskStartScenarioInPlace(ped, GetHashKey(randomAnim), 0, true)

    if Framework == 'rsg' then
        exports['rsg-target']:AddTargetEntity(ped, {
            options = {
                {
                    type = "client",
                    event = "rsg-shop:client:openShop",
                    icon = "fas fa-shopping-basket",
                    label = "Open Shop",
                    shopName = shopData.name,
                    items = shopData.items
                },
            },
            distance = Config.ShopkeeperSettings.interactionDistance
        })
    else
        local str = CreateVarString(10, 'LITERAL_STRING', "Open Shop")
        local prompt = PromptRegisterBegin()
        PromptSetControlAction(prompt, 0xDFF812F9)
        PromptSetText(prompt, str)
        PromptSetEnabled(prompt, true)
        PromptSetVisible(prompt, true)
        PromptSetHoldMode(prompt, false)
        PromptSetGroup(prompt, 0)
        PromptRegisterEnd(prompt)
        
        table.insert(prompts, {
            prompt = prompt,
            ped = ped,
            shopData = shopData
        })
    end

    SetShopkeeperActive(shopData.name, true)
    return ped
end

local function RespawnShopkeeper(shopData)
    if not Config.ShopkeeperSettings.enableRespawn or isResourceStopping then return end
    
    DebugPrint("Respawning shopkeeper for: " .. shopData.name, 'info')
    local ped = CreateShopkeeper(shopData.pedModel, shopData.pedCoords, shopData)
    if ped then
        table.insert(shopPeds, ped)
        DebugPrint("Shopkeeper respawned for: " .. shopData.name, 'success')
    end
end

CreateThread(function()
    if isInitialized then return end
    CleanupShopkeepers()
    DebugPrint("Starting shop initialization...", 'info')
    for i, shop in pairs(Config.Shops) do
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, shop.coords.x, shop.coords.y, shop.coords.z)
        SetBlipSprite(blip, 1475879926, 1)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, shop.name)
        table.insert(shopBlips, blip)
        DebugPrint("Created blip for shop: " .. shop.name, 'debug')

        local ped = CreateShopkeeper(shop.pedModel, shop.pedCoords, shop)
        if ped then
            DebugPrint("Created shopkeeper for: " .. shop.name, 'debug')
            table.insert(shopPeds, ped)
        end
    end
    isInitialized = true
    DebugPrint("Shop initialization completed", 'success')
end)

CreateThread(function()
    while true do
        Wait(1000)
        if isResourceStopping then return end
        
        for i, ped in pairs(shopPeds) do
            if not DoesEntityExist(ped) or IsEntityDead(ped) then
                local shopData = Config.Shops[i]
                if shopData then
                    DebugPrint("Shopkeeper died for: " .. shopData.name, 'error')
                    table.remove(shopPeds, i)
                    SetShopkeeperActive(shopData.name, false)
                    deadShopkeepers[shopData.name] = GetGameTimer()
                    
                    CreateThread(function()
                        Wait(Config.ShopkeeperSettings.respawnTime * 1000)
                        if deadShopkeepers[shopData.name] and not isResourceStopping then
                            RespawnShopkeeper(shopData)
                            deadShopkeepers[shopData.name] = nil
                        end
                    end)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    DebugPrint("Resource stopping, cleaning up...", 'info')
    isResourceStopping = true
    CleanupShopkeepers()
    DebugPrint("Cleanup completed", 'success')
end)

RegisterNetEvent('rsg-shop:client:openShop')
AddEventHandler('rsg-shop:client:openShop', function(data)
    local waitTimes = {
        [1] = math.random(2000, 2250)
    }
    Wait(waitTimes[1])
    local shopName = nil
    local items = nil
    
    if type(data) == 'table' then
        shopName = data.shopName
        items = data.items
    else
        shopName = data
    end
    
    DebugPrint('Opening shop: ' .. tostring(shopName), 'info')
    local shopConfig = nil
    for _, shop in pairs(Config.Shops) do
        if shop.name == shopName then
            shopConfig = shop
            break
        end
    end
    
    if not shopConfig then
        DebugPrint('Shop not found: ' .. tostring(shopName), 'error')
        return
    end
    local shopItems = items or shopConfig.items
    local shopPaymentMethods = Config.PaymentMethods
    
    DebugPrint('Items: ' .. json.encode(shopItems), 'debug')
    DebugPrint('Payment Methods: ' .. json.encode(shopPaymentMethods), 'debug')

    SendNUIMessage({
        type = 'open',
        shopName = shopName,
        items = shopItems,
        paymentMethods = shopPaymentMethods
    })
    SetNuiFocus(true, true)
    DebugPrint('Shop UI opened', 'success')
end)

RegisterNetEvent('rsg-shop:client:updateCart')
AddEventHandler('rsg-shop:client:updateCart', function(cartItems)
    DebugPrint('Updating cart with items: ' .. json.encode(cartItems), 'debug')
    SendNUIMessage({
        type = 'updateCart',
        cart = cartItems
    })
    DebugPrint('Cart updated', 'success')
end)

RegisterNetEvent('rsg-shop:client:closeShop')
AddEventHandler('rsg-shop:client:closeShop', function()
    DebugPrint('Closing shop UI', 'info')
    SendNUIMessage({
        type = 'close'
    })
    SetNuiFocus(false, false)
    cart = {} -- Clear the cart
    DebugPrint('Shop UI closed and cart cleared', 'success')
end)

-- RegisterCommand('openshop', function(source, args, rawCommand)
--     local waitTimes = {
--         [1] = math.random(2000, 5000)
--     }
--     Wait(waitTimes[1])
--     local shopName = args[2] or "Valentine General Store"
--     DebugPrint('Attempting to open shop: ' .. shopName, 'debug')

--     local shopConfig = nil
--     for _, shop in pairs(Config.Shops) do
--         if shop.name == shopName then
--             shopConfig = shop
--             break
--         end
--     end

--     if not shopConfig then
--         DebugPrint('Shop not found: ' .. shopName, 'error')
--         return
--     end

--     if Framework == 'rsg' then
--         Core.Functions.TriggerCallback('rsg-shop:server:getShopItems', function(items, paymentMethods)
--             DebugPrint('Received shop items from server', 'debug')
--             TriggerEvent('rsg-shop:client:openShop', shopName, items or shopConfig.items, paymentMethods or Config.PaymentMethods)
--         end, shopName)
--     else
--         Core.Callback.TriggerAsync('rsg-shop:server:getShopItems', function(items, paymentMethods)
--             DebugPrint('Received shop items from server', 'debug')
--             TriggerEvent('rsg-shop:client:openShop', shopName, items or shopConfig.items, paymentMethods or Config.PaymentMethods)
--         end, shopName)
--     end
-- end, false)

RegisterNuiCallback('close', function(data, cb)
    DebugPrint('Received NUI callback: close', 'debug')
    SendNUIMessage({
        type = 'close'
    })
    SetNuiFocus(false, false)
    cart = {} -- Clear the cart
    cb('ok')
    DebugPrint('Shop UI closed and cart cleared', 'success')
end)

RegisterNuiCallback('purchase', function(data, cb)
    DebugPrint('Received NUI callback: purchase', 'debug')
    DebugPrint('Purchase Data: ' .. json.encode(data), 'debug')
    TriggerServerEvent('rsg-shop:server:processPurchase', data)
    cart = {} -- Clear the cart
    SendNUIMessage({
        type = 'close'
    })
    SetNuiFocus(false, false)
    cb('ok')
    DebugPrint('Purchase completed and shop closed', 'success')
end)

if Framework == 'vorp' then
    CreateThread(function()
        while true do
            Wait(0)
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            
            for _, promptData in pairs(prompts) do
                if DoesEntityExist(promptData.ped) and not IsEntityDead(promptData.ped) then
                    local pedCoords = GetEntityCoords(promptData.ped)
                    local distance = #(coords - pedCoords)
                    
                    if distance < Config.ShopkeeperSettings.interactionDistance then
                        local promptGroup = CreateVarString(10, 'LITERAL_STRING', "Shop")
                        PromptSetActiveGroupThisFrame(promptGroup, promptData.prompt)
                        
                        if Citizen.InvokeNative(0xE0F65F0640EF0617, promptData.prompt) then
                            TriggerEvent('rsg-shop:client:openShop', promptData.shopData.name, promptData.shopData.items, Config.PaymentMethods)
                        end
                    end
                end
            end
        end
    end)
end