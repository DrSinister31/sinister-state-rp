"""Fix both AI scripts: upload corrected medical_ai.lua and fix police_ai.lua."""
import paramiko, os

HOST = 'nyc15.xgamingserver.com'
PORT = 2022
USER = 'nhxija4f.69162937'
PASS = 'Familia1!'

PROJECT = r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master"

# Fix medical_ai.lua
medical_path = os.path.join(PROJECT, "sinister_ai", "server", "medical_ai.lua")
with open(medical_path) as f:
    content = f.read()

# Replace client-only natives with server-safe versions
content = content.replace("RequestModel(hash)", "-- RequestModel removed (client-only native)")
content = content.replace("while not HasModelLoaded(hash) do Wait(0) end", "-- HasModelLoaded removed (client-only native)")
content = content.replace("GetActivePlayers()", "GetPlayers()")

# Replace SpawnMedicalAI function to be server-safe
old_spawn = """function SpawnMedicalAI(hospital)
    if not AI_ENABLED then return end
    local count = GetDensityCapped(3)
    if count < 1 then return end

    local loc = hospital.coords
    for i = 1, count do
        local modelName = MEDICAL_MODELS.doctor[(i % #MEDICAL_MODELS.doctor) + 1]
        local hash = GetHashKey(modelName)
        -- RequestModel removed (client-only native)
        -- HasModelLoaded removed (client-only native)

        local offsetX = math.random(-5, 5)
        local offsetY = math.random(-5, 5)
        local ped = CreatePed(0, hash, loc.x + offsetX, loc.y + offsetY, loc.z, loc.w, true, true)
        TagAI(ped, "medical", "doctor", hospital.label, 0.0)
        TaskWanderStandard(ped, 10.0, 10)

        activeDoctors[#activeDoctors + 1] = { ped = ped, hospital = hospital }
    end
end"""

new_spawn = """function SpawnMedicalAI(hospital)
    if not AI_ENABLED then return end
    local count = GetDensityCapped(3)
    if count < 1 then return end

    local loc = hospital.coords
    for i = 1, count do
        local modelName = MEDICAL_MODELS.doctor[(i % #MEDICAL_MODELS.doctor) + 1]
        local hash = GetHashKey(modelName)

        local offsetX = math.random(-5, 5)
        local offsetY = math.random(-5, 5)
        local ped = Citizen.InvokeNative(0xD49F9B0955C367DE, hash, loc.x + offsetX, loc.y + offsetY, loc.z, loc.w, true, true, false)
        if ped > 0 then
            TagAI(ped, "medical", "doctor", hospital.label, 0.0)
            activeDoctors[#activeDoctors + 1] = { ped = ped, hospital = hospital }
        end
    end
end"""

content = content.replace(old_spawn, new_spawn)

with open(medical_path, 'w') as f:
    f.write(content)

# Fix police_ai.lua
police_path = os.path.join(PROJECT, "sinister_ai", "server", "police_ai.lua")
with open(police_path) as f:
    content = f.read()

content = content.replace("RequestModel(hash)", "-- RequestModel removed (client-only native)")
content = content.replace("while not HasModelLoaded(hash) do Wait(0) end", "-- HasModelLoaded removed (client-only native)")
content = content.replace("GetActivePlayers()", "GetPlayers()")

with open(police_path, 'w') as f:
    f.write(content)

print("Local files fixed. Uploading...")

# Upload
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(HOST, PORT, USER, PASS, timeout=30)
sftp = ssh.open_sftp()

sftp.put(medical_path, '/resources/[standalone]/sinister_ai/server/medical_ai.lua')
sftp.put(police_path, '/resources/[standalone]/sinister_ai/server/police_ai.lua')

print("medical_ai.lua uploaded")
print("police_ai.lua uploaded")

sftp.close()
ssh.close()
print("Done. Restart server.")
