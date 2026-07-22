local args = { ... }

local owner = args[1]
local repository = args[2] or "CraftBot"
local branch = args[3] or "main"

if not owner or owner == "" then
    print("Installation CraftBot depuis GitHub")
    print("")
    print("Utilisation :")
    print("install <utilisateur> [depot] [branche]")
    print("")
    print("Exemple :")
    print("install Benjamin CraftBot main")
    return
end

if not http or not http.get then
    error("L'API HTTP doit etre activee dans la configuration du serveur")
end

local base = "https://raw.githubusercontent.com/"
    .. owner .. "/" .. repository .. "/" .. branch

local function parent(path)
    local directory = fs.getDir(path)
    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

local function download(relative, destination)
    write("Telechargement " .. relative .. " ... ")

    local response, err = http.get(base .. "/" .. relative, nil, true)
    if not response then
        printError("ECHEC")
        error(tostring(err or "Telechargement impossible"), 0)
    end

    local data = response.readAll()
    response.close()

    parent(destination)

    local temp = destination .. ".download"
    if fs.exists(temp) then fs.delete(temp) end

    local file = fs.open(temp, "wb")
    if not file then error("Impossible d'ecrire " .. temp, 0) end

    file.write(data)
    file.close()

    if fs.exists(destination) then fs.delete(destination) end
    fs.move(temp, destination)

    print("OK")
end

download("manifest.lua", "/downloads/github-manifest.lua")

local manifestChunk, manifestError =
    loadfile("/downloads/github-manifest.lua")

if not manifestChunk then error(manifestError, 0) end

local manifest = manifestChunk()

for _, relative in ipairs(manifest.managerFiles or {}) do
    download(relative, "/" .. relative)
end

for _, package in ipairs(manifest.packages or {}) do
    for _, relative in ipairs(package.files or {}) do
        local source = "packages/" .. package.folder .. "/" .. relative
        local destination = "/" .. source
        download(source, destination)
    end
end

local config = fs.open("/config/repository.lua", "w")
config.writeLine("return {")
config.writeLine("    enabled = true,")
config.writeLine('    owner = "' .. owner .. '",')
config.writeLine('    repository = "' .. repository .. '",')
config.writeLine('    branch = "' .. branch .. '"')
config.writeLine("}")
config.close()

print("")
print("CraftBot Manager " .. tostring(manifest.managerVersion) .. " installe.")
print("Redemarrage...")

sleep(1)
os.reboot()
