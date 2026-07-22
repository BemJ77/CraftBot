local function loadTable(path)
    local fn, err = loadfile(path)
    if not fn then return nil, err end
    local ok, value = pcall(fn)
    if not ok then return nil, value end
    return value
end

local cfg, cfgError = loadTable("/config/repository.lua")
if not cfg then error(cfgError, 0) end
if cfg.enabled ~= true then error("Depot GitHub non configure", 0) end

local base = "https://raw.githubusercontent.com/"
    .. cfg.owner .. "/"
    .. cfg.repository .. "/"
    .. (cfg.branch or "main")

local function ensureParent(path)
    local parent = fs.getDir(path)
    if parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end
end

local function download(relative, destination)
    write("Mise a jour " .. relative .. " ... ")

    local response, err = http.get(base .. "/" .. relative, nil, true)
    if not response then
        printError("ECHEC")
        return false, err
    end

    local data = response.readAll()
    response.close()

    ensureParent(destination)

    local temp = destination .. ".update"
    if fs.exists(temp) then fs.delete(temp) end

    local file = fs.open(temp, "wb")
    if not file then return false, "Ecriture impossible" end
    file.write(data)
    file.close()

    if fs.exists(destination) then fs.delete(destination) end
    fs.move(temp, destination)

    print("OK")
    return true
end

if not fs.exists("/downloads") then fs.makeDir("/downloads") end

local ok, err = download("manifest.lua", "/downloads/github-manifest.lua")
if not ok then error(err, 0) end

local manifest, manifestError =
    loadTable("/downloads/github-manifest.lua")

if not manifest then error(manifestError, 0) end

for _, relative in ipairs(manifest.managerFiles or {}) do
    local downloaded, downloadError =
        download(relative, "/" .. relative)

    if not downloaded then error(downloadError, 0) end
end

print("")
print("Manager mis a jour vers " .. tostring(manifest.managerVersion))
print("Redemarrage...")
sleep(1)
os.reboot()
