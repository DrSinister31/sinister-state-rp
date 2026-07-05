local currentWeatherType = 'EXTRASUNNY'
local currentTemp = 72
local currentZone = 'houston'
local currentWindSpeed = 5
local currentWindDir = 'SW'
local currentHumidity = 45
local currentAlert = nil
local currentForecast = {}
local lastWeatherCheck = 0

local WEATHER_TYPES = {
    'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'OVERCAST', 'RAIN', 'THUNDER',
    'CLEARING', 'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'HALLOWEEN'
}

local WEATHER_NAMES = {
    EXTRASUNNY = 'Extremely Sunny',
    CLEAR       = 'Clear',
    CLOUDS      = 'Cloudy',
    OVERCAST    = 'Overcast',
    RAIN        = 'Rain',
    THUNDER     = 'Thunderstorm',
    CLEARING    = 'Clearing',
    SNOW        = 'Snow',
    BLIZZARD    = 'Blizzard',
    SNOWLIGHT   = 'Light Snow',
    XMAS        = 'Snow',
    HALLOWEEN   = 'Spooky Fog',
}

local BASE_TEMPERATURES = {
    EXTRASUNNY = 95,
    CLEAR       = 82,
    CLOUDS      = 72,
    OVERCAST    = 65,
    RAIN        = 58,
    THUNDER     = 55,
    CLEARING    = 70,
    SNOW        = 28,
    BLIZZARD    = 18,
    SNOWLIGHT   = 34,
    XMAS        = 30,
    HALLOWEEN   = 62,
}

local ZONE_OFFSETS = {
    houston    = 5,
    fortworth  = 0,
    killeen    = -3,
    wilderness = 2,
}

function getWindDirection()
    local dirs = { 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' }
    local dirIndex = math.random(1, #dirs)
    local windDir = dirs[dirIndex]
    local windSpeed = math.random(0, 25)
    return windDir, windSpeed
end

function calculateTemperature(weatherType, zone)
    local base = BASE_TEMPERATURES[weatherType] or 72
    local offset = ZONE_OFFSETS[zone] or 0
    local variation = math.random(-2, 2)

    if zone == 'houston' and (weatherType == 'EXTRASUNNY' or weatherType == 'CLEAR') then
        variation = variation + math.random(1, 3)
    end

    if zone == 'killeen' and weatherType == 'RAIN' then
        variation = variation - math.random(0, 2)
    end

    return base + offset + variation
end

function buildForecast(weatherType, zone)
    local forecast = {}
    local weatherKeys = {}

    for k, _ in pairs(BASE_TEMPERATURES) do
        weatherKeys[#weatherKeys + 1] = k
    end

    local hours = { '+1h', '+2h', '+3h', '+4h', '+5h', '+6h' }

    for i = 1, 6 do
        local nextWeather
        local rand = math.random()

        if rand < 0.6 then
            nextWeather = weatherType
        elseif rand < 0.8 then
            local nearbyIdx = 1
            for j, wk in ipairs(weatherKeys) do
                if wk == weatherType then
                    nearbyIdx = j
                    break
                end
            end
            local offset = math.random(-2, 2)
            if offset == 0 then offset = 1 end
            local newIdx = nearbyIdx + offset
            if newIdx < 1 then newIdx = 1 end
            if newIdx > #weatherKeys then newIdx = #weatherKeys end
            nextWeather = weatherKeys[newIdx]
        else
            local idx = math.random(1, #weatherKeys)
            nextWeather = weatherKeys[idx]
        end

        if i > 1 and nextWeather == forecast[i - 1].weather and math.random() < 0.3 then
            local idx = math.random(1, #weatherKeys)
            nextWeather = weatherKeys[idx]
        end

        local temp = calculateTemperature(nextWeather, zone)

        if i > 1 then
            local prevTemp = forecast[i - 1].temp
            local maxDiff = 8
            if math.abs(temp - prevTemp) > maxDiff then
                if temp > prevTemp then
                    temp = prevTemp + math.random(1, maxDiff)
                else
                    temp = prevTemp - math.random(1, maxDiff)
                end
            end
        end

        forecast[i] = {
            time = hours[i],
            weather = nextWeather,
            weatherName = WEATHER_NAMES[nextWeather] or nextWeather,
            temp = temp,
        }
    end

    return forecast
end

function getCurrentWeather()
    local weatherType = currentWeatherType or 'EXTRASUNNY'
    local temp = currentTemp or 72
    local zone = currentZone or 'houston'
    local windDir = currentWindDir or 'SW'
    local windSpeed = currentWindSpeed or 5
    local humidity = currentHumidity or 45
    local alert = currentAlert
    local forecast = currentForecast

    return {
        weather = weatherType,
        weatherName = WEATHER_NAMES[weatherType] or weatherType,
        temp = temp,
        zone = zone,
        windSpeed = windSpeed,
        windDir = windDir,
        humidity = humidity,
        alert = alert,
        forecast = forecast,
    }
end

exports('getCurrentWeather', getCurrentWeather)

function syncWeather()
    local weatherType = GetConvar('setr_weather', nil)

    if not weatherType then
        local renewedState = GlobalState.windyState
        if renewedState and renewedState.current_weather then
            weatherType = renewedState.current_weather
        end
    end

    if not weatherType then
        weatherType = GlobalState.weatherType or GlobalState.CURRENT_WEATHER
    end

    if not weatherType then
        weatherType = 'EXTRASUNNY'
    end

    local weatherChanged = (weatherType ~= currentWeatherType)
    local needsUpdate = (GetGameTimer() - lastWeatherCheck > 30000)

    if weatherChanged or needsUpdate then
        currentWeatherType = weatherType

        local windDir, windSpeed = getWindDirection()
        currentWindDir = windDir
        currentWindSpeed = windSpeed

        local temp = calculateTemperature(weatherType, currentZone)
        currentTemp = temp

        local humidity = math.random(30, 90)
        if weatherType == 'RAIN' or weatherType == 'THUNDER' then
            humidity = math.random(70, 98)
        elseif weatherType == 'EXTRASUNNY' or weatherType == 'CLEAR' then
            humidity = math.random(25, 55)
        end
        currentHumidity = humidity

        local alert = nil
        if weatherType == 'THUNDER' then
            alert = 'Severe Thunderstorm Warning - Take shelter!'
        elseif weatherType == 'BLIZZARD' then
            alert = 'Blizzard Warning - Extreme cold, stay indoors!'
        elseif weatherType == 'SNOW' and currentTemp < 25 then
            alert = 'Winter Weather Advisory - Roads may be icy'
        elseif weatherType == 'RAIN' and currentWindSpeed > 15 then
            alert = 'Wind Advisory - Gusty winds with rain'
        end
        currentAlert = alert

        currentForecast = buildForecast(weatherType, currentZone)

        local stateData = {
            weather = currentWeatherType,
            weatherName = WEATHER_NAMES[currentWeatherType] or currentWeatherType,
            temp = currentTemp,
            zone = currentZone,
            windSpeed = currentWindSpeed,
            windDir = currentWindDir,
            humidity = currentHumidity,
            alert = currentAlert,
            forecast = currentForecast,
        }

        GlobalState['sinister:weather'] = stateData

        if currentAlert then
            TriggerEvent('sinister:weather:alert', currentAlert)
            GlobalState['sinister:weather:alert'] = {
                message = currentAlert,
                time = os.time(),
                weather = currentWeatherType,
            }
        end

        lastWeatherCheck = GetGameTimer()
    end
end

function getCurrentWeatherExport()
    return getCurrentWeather()
end

AddEventHandler('syn_weather:serverSync', function(weatherType)
    if weatherType then
        currentWeatherType = weatherType
    end
end)

AddEventHandler('playerJoining', function()
    local stateData = {
        weather = currentWeatherType,
        weatherName = WEATHER_NAMES[currentWeatherType] or currentWeatherType,
        temp = currentTemp,
        zone = currentZone,
        windSpeed = currentWindSpeed,
        windDir = currentWindDir,
        humidity = currentHumidity,
        alert = currentAlert,
        forecast = currentForecast,
    }

    GlobalState['sinister:weather'] = stateData
end)

RegisterNetEvent('sinister:weather:requestSync', function()
    local src = source
    local stateData = {
        weather = currentWeatherType,
        weatherName = WEATHER_NAMES[currentWeatherType] or currentWeatherType,
        temp = currentTemp,
        zone = currentZone,
        windSpeed = currentWindSpeed,
        windDir = currentWindDir,
        humidity = currentHumidity,
        alert = currentAlert,
        forecast = currentForecast,
    }

    TriggerClientEvent('sinister:weather:sync', src, stateData)
end)

RegisterCommand('setweather', function(source, args, raw)
    local weatherType = args[1] and args[1]:upper() or 'EXTRASUNNY'

    local validWeather = false
    for _, wt in ipairs(WEATHER_TYPES) do
        if wt == weatherType then
            validWeather = true
            break
        end
    end

    if not validWeather then
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 60, 30 },
                args = { 'Weather', 'Invalid weather type. Valid: ' .. table.concat(WEATHER_TYPES, ', ') }
            })
        end
        return
    end

    currentWeatherType = weatherType
    syncWeather()

    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 191, 87, 0 },
            args = { 'Weather', 'Weather set to ' .. (WEATHER_NAMES[weatherType] or weatherType) .. ' (' .. currentTemp .. '°F)' }
        })
    end
end, true)

RegisterCommand('synczone', function(source, args, raw)
    local zone = args[1] and args[1]:lower() or 'houston'

    local validZones = { houston = true, fortworth = true, killeen = true, wilderness = true }
    if not validZones[zone] then
        if source > 0 then
            TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 60, 30 },
                args = { 'Weather', 'Invalid zone. Valid: houston, fortworth, killeen, wilderness' }
            })
        end
        return
    end

    currentZone = zone
    currentTemp = calculateTemperature(currentWeatherType, currentZone)
    syncWeather()

    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 191, 87, 0 },
            args = { 'Weather', 'Zone synced to ' .. zone .. ' (' .. currentTemp .. '°F)' }
        })
    end
end, true)

Citizen.CreateThread(function()
    Citizen.Wait(5000)

    syncWeather()

    while true do
        Citizen.Wait(30000)
        syncWeather()
    end
end)
