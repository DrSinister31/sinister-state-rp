local currentWeather = nil
local currentZone = 'houston'
local currentTemp = 72
local currentWindSpeed = 5
local currentWindDir = 'SW'
local currentHumidity = 45
local currentAlert = nil
local currentForecast = {}

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
    FOG         = 'Foggy',
    WIND        = 'Windy',
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

local ZONE_BOUNDS = {
    {
        name = 'houston',
        minX = 200.0, maxX = 400.0,
        minY = -1100.0, maxY = -700.0,
    },
    {
        name = 'fortworth',
        minX = -400.0, maxX = 400.0,
        minY = 5500.0, maxY = 6800.0,
    },
    {
        name = 'killeen',
        minX = 1000.0, maxX = 2500.0,
        minY = 3000.0, maxY = 4500.0,
    },
}

function isCoordInZone(x, y, zone)
    return x >= zone.minX and x <= zone.maxX and y >= zone.minY and y <= zone.maxY
end

function detectZone()
    local ped = PlayerPedId()
    if not ped or ped == 0 then return 'wilderness' end

    local coords = GetEntityCoords(ped)
    if not coords then return 'wilderness' end

    for _, zone in ipairs(ZONE_BOUNDS) do
        if isCoordInZone(coords.x, coords.y, zone) then
            return zone.name
        end
    end

    return 'wilderness'
end

function getWindDirection()
    local dirs = { 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' }
    local dirIndex = math.random(1, #dirs)
    local windDir = dirs[dirIndex]
    local windSpeed = math.random(0, 25)
    return windDir, windSpeed
end

function getGameTimeData()
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    local timeStr = string.format('%02d:%02d', hour, minute)
    local sunrise = '06:30'
    local sunset = '20:15'

    if hour >= 6 and hour < 20 then
        sunrise = '06:28'
        sunset = '20:12'
    elseif hour >= 20 or hour < 6 then
        sunrise = '06:42'
        sunset = '20:08'
    end

    if hour >= 5 and hour < 8 then
        sunrise = string.format('%02d:00', hour)
    elseif hour >= 19 and hour < 22 then
        sunset = string.format('%02d:00', hour)
    end

    return {
        time = timeStr,
        sunrise = sunrise,
        sunset = sunset,
        hour = hour,
        minute = minute,
        isNight = (hour >= 20 or hour < 6),
    }
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

function buildWeatherData(weatherType, zone)
    if not weatherType then
        weatherType = currentWeather or 'EXTRASUNNY'
    end
    if not zone then
        zone = detectZone()
    end

    local windDir, windSpeed = getWindDirection()
    local temp = calculateTemperature(weatherType, zone)
    local humidity = math.random(30, 90)

    if weatherType == 'RAIN' or weatherType == 'THUNDER' then
        humidity = math.random(70, 98)
    elseif weatherType == 'EXTRASUNNY' or weatherType == 'CLEAR' then
        humidity = math.random(25, 55)
    end

    local timeData = getGameTimeData()

    local alert = nil
    if weatherType == 'THUNDER' then
        alert = 'Severe Thunderstorm Warning - Take shelter!'
    elseif weatherType == 'BLIZZARD' then
        alert = 'Blizzard Warning - Extreme cold, stay indoors!'
    elseif weatherType == 'SNOW' and currentTemp < 25 then
        alert = 'Winter Weather Advisory - Roads may be icy'
    elseif weatherType == 'RAIN' and windSpeed > 15 then
        alert = 'Wind Advisory - Gusty winds with rain'
    end

    local data = {
        weather = weatherType,
        weatherName = WEATHER_NAMES[weatherType] or weatherType,
        temp = temp,
        zone = zone,
        windSpeed = windSpeed,
        windDir = windDir,
        humidity = humidity,
        alert = alert,
        time = timeData.time,
        sunrise = timeData.sunrise,
        sunset = timeData.sunset,
        isNight = timeData.isNight,
        forecast = buildForecast(weatherType, zone),
    }

    return data
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

AddStateBagChangeHandler('sinister:weather', nil, function(bagName, key, value)
    if not value then return end

    currentWeather = value.weather
    currentTemp = value.temp
    currentZone = value.zone
    currentWindSpeed = value.windSpeed
    currentWindDir = value.windDir
    currentHumidity = value.humidity
    currentAlert = value.alert
    currentForecast = value.forecast or {}

    SendNUIMessage({
        type = 'weatherUpdate',
        weather = currentWeather,
        weatherName = WEATHER_NAMES[currentWeather] or currentWeather,
        temp = currentTemp,
        zone = currentZone,
        windSpeed = currentWindSpeed,
        windDir = currentWindDir,
        humidity = currentHumidity,
        alert = currentAlert,
        forecast = currentForecast,
    })

    if currentAlert then
        TriggerEvent('sinister:weather:alert', currentAlert)
    end
end)

RegisterNUICallback('getWeather', function(data, cb)
    local zone = detectZone()
    local weatherType = currentWeather or 'EXTRASUNNY'
    local weatherData = buildWeatherData(weatherType, zone)

    currentZone = zone
    currentTemp = weatherData.temp
    currentWindSpeed = weatherData.windSpeed
    currentWindDir = weatherData.windDir
    currentHumidity = weatherData.humidity
    currentAlert = weatherData.alert
    currentForecast = weatherData.forecast

    cb(weatherData)
end)

RegisterNUICallback('getForecast', function(data, cb)
    local zone = data.zone or detectZone()
    local weatherType = currentWeather or 'EXTRASUNNY'
    local forecast = buildForecast(weatherType, zone)

    currentForecast = forecast
    cb({ forecast = forecast })
end)

RegisterNUICallback('getTime', function(data, cb)
    local timeData = getGameTimeData()
    cb(timeData)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        return
    end
end)

function getCurrentWeather()
    local zone = detectZone()
    local weatherType = currentWeather or 'EXTRASUNNY'
    return buildWeatherData(weatherType, zone)
end

exports('getCurrentWeather', getCurrentWeather)

RegisterCommand('weather', function(source, args, raw)
    local data = getCurrentWeather()
    local msg = string.format(
        'Weather: %s | %d°F | Zone: %s | Wind: %s %d mph | Humidity: %d%%',
        data.weatherName, data.temp, data.zone, data.windDir, data.windSpeed, data.humidity
    )
    TriggerEvent('chat:addMessage', {
        color = { 191, 87, 0 },
        multiline = true,
        args = { 'Weather', msg }
    })

    if data.alert then
        TriggerEvent('chat:addMessage', {
            color = { 255, 60, 30 },
            multiline = true,
            args = { 'Alert', data.alert }
        })
    end

    if data.forecast and #data.forecast > 0 then
        local forecastMsg = 'Forecast: '
        for _, f in ipairs(data.forecast) do
            forecastMsg = forecastMsg .. string.format('%s %s %d°F | ', f.time, f.weatherName, f.temp)
        end
        TriggerEvent('chat:addMessage', {
            color = { 180, 130, 60 },
            multiline = true,
            args = { 'Forecast', forecastMsg }
        })
    end
end, false)

Citizen.CreateThread(function()
    Citizen.Wait(2000)

    local currentResource = GetCurrentResourceName()
    local stateBagValue = GlobalState['sinister:weather']

    if stateBagValue then
        currentWeather = stateBagValue.weather
        currentTemp = stateBagValue.temp
        currentZone = stateBagValue.zone
        currentWindSpeed = stateBagValue.windSpeed
        currentWindDir = stateBagValue.windDir
        currentHumidity = stateBagValue.humidity
        currentAlert = stateBagValue.alert
        currentForecast = stateBagValue.forecast or {}
    end
end)
