local remote = {}

local logger = require("core.logger")
local version = require("core.version")

local CONFIG_PATH = "/config/repository.lua"
local CATALOG_PATH = "/downloads/catalog.lua"

local function loadTable(path)
    if not fs.exists(path) or fs.isDir(path) then
        return nil, "Fichier absent : " .. path
    end

    local fn, err = loadfile(path)
    if not fn then return nil, err end

    local ok, value = pcall(fn)
    if not ok then return nil, value end
    if type(value) ~= "table" then
        return nil, "Table Lua attendue : " .. path
    end

    return value
end

local function config()
    local value, err = loadTable(CONFIG_PATH)
    if not value then return nil, err end

    if value.enabled ~= true then
        return nil, "Depot GitHub non configure"
    end

    if not value.owner or value.owner == ""
        or value.owner == "VOTRE_UTILISATEUR" then
        return nil, "Proprietaire GitHub non configure"
    end

    if not value.repository or value.repository == "" then
        return nil, "Nom du depot GitHub non configure"
    end

    return value
end

local function rawBase(cfg)
    return "https://raw.githubusercontent.com/"
        .. cfg.owner .. "/"
        .. cfg.repository .. "/"
        .. (cfg.branch or "main")
end

local function ensureParent(path)
    local parent = fs.getDir(path)
    if parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end
end

local function download(url, destination)
    if not http or not http.get then
        return false, "API HTTP indisponible"
    end

    local response, err = http.get(url, nil, true)
    if not response then
        return false, tostring(err or "Telechargement impossible")
    end

    local data = response.readAll()
    response.close()

    if data == nil then
        return false, "Reponse vide"
    end

    ensureParent(destination)

    local temp = destination .. ".download"
    if fs.exists(temp) then fs.delete(temp) end

    local handle = fs.open(temp, "wb")
    if not handle then
        return false, "Impossible d'ecrire " .. temp
    end

    handle.write(data)
    handle.close()

    if fs.exists(destination) then fs.delete(destination) end
    fs.move(temp, destination)

    return true
end

local function localPackageVersion(folder)
    local metadata = "/packages/" .. folder .. "/package.lua"
    local value = loadTable(metadata)
    if not value then return nil end
    return value.version
end

local function downloadPackage(base, entry, onProgress, offset, total)
    local staging = "/downloads/packages/" .. entry.folder

    if fs.exists(staging) then fs.delete(staging) end
    fs.makeDir(staging)

    for index, relative in ipairs(entry.files or {}) do
        if onProgress then
            onProgress(
                offset + index - 1,
                total,
                entry.folder .. "/" .. relative,
                "Telechargement"
            )
        end

        local destination = fs.combine(staging, relative)
        local url = base
            .. "/packages/"
            .. entry.folder
            .. "/"
            .. relative

        local ok, err = download(url, destination)
        if not ok then
            return false,
                entry.folder .. "/" .. relative .. " : " .. tostring(err)
        end
    end

    local final = "/packages/" .. entry.folder
    local old = final .. ".old"

    if fs.exists(old) then fs.delete(old) end
    if fs.exists(final) then fs.move(final, old) end

    local moved, moveError = pcall(fs.move, staging, final)
    if not moved then
        if fs.exists(old) and not fs.exists(final) then
            fs.move(old, final)
        end
        return false, tostring(moveError)
    end

    if fs.exists(old) then fs.delete(old) end
    return true
end

function remote.syncPackages(onProgress)
    local result = {
        success = false,
        updated = 0,
        errors = {}
    }

    local cfg, cfgError = config()
    if not cfg then
        result.errors[1] = cfgError
        return result
    end

    if not fs.exists("/downloads") then fs.makeDir("/downloads") end

    local base = rawBase(cfg)
    local ok, err = download(base .. "/catalog.lua", CATALOG_PATH)
    if not ok then
        result.errors[1] = "Catalogue GitHub : " .. tostring(err)
        return result
    end

    local catalog, catalogError = loadTable(CATALOG_PATH)
    if not catalog then
        result.errors[1] = "Catalogue invalide : " .. tostring(catalogError)
        return result
    end

    local pending = {}
    local totalFiles = 0

    for _, entry in ipairs(catalog.packages or {}) do
        local current = localPackageVersion(entry.folder)
        if not current or version.compare(entry.version, current) > 0 then
            pending[#pending + 1] = entry
            totalFiles = totalFiles + #(entry.files or {})
        end
    end

    local offset = 0
    for _, entry in ipairs(pending) do
        local downloaded, downloadError =
            downloadPackage(base, entry, onProgress, offset, totalFiles)

        if downloaded then
            result.updated = result.updated + 1
        else
            result.errors[#result.errors + 1] = downloadError
            logger.error("GitHub : " .. tostring(downloadError))
        end

        offset = offset + #(entry.files or {})
    end

    if onProgress and totalFiles > 0 then
        onProgress(totalFiles, totalFiles, "Synchronisation terminee", "Termine")
    end

    result.success = #result.errors == 0
    return result
end

return remote
