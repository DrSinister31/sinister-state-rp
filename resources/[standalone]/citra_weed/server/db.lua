local function jsonData(plant)
    return json.encode({
        coords = plant.coords,
        planted = plant.planted,
        water = plant.water,
        food = plant.food,
        health = plant.health,
        percentage = plant.percentage,
        gender = plant.gender,
    })
end

return {
    init = function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `citra_weed_plants` (
                `id` int AUTO_INCREMENT,
                `data` TEXT DEFAULT '[]' NOT NULL,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]], {})
    end,
    save = function(plant)
        local data = jsonData(plant)
        MySQL.update("UPDATE `citra_weed_plants` SET data = @data WHERE id = @id", {
            id = plant.id,
            data = data,
        })
    end,
    new = function(plant)
        local data = jsonData(plant)
        return MySQL.insert.await("INSERT INTO `citra_weed_plants` (`data`) VALUES (?)", {data})
    end,
    delete = function(id)
        MySQL.query("DELETE FROM `citra_weed_plants` WHERE id = ?", {id})
    end,
    getAll = function()
        return MySQL.query.await("SELECT * FROM `citra_weed_plants`", {})
    end,
}
