-- ============================================================
-- CraftBot Manager - Installateur GitHub
-- Version robuste, sans arguments
-- Depot : BemJ77/CraftBot
-- ============================================================

local OWNER = "BemJ77"
local REPOSITORY = "CraftBot"
local BRANCH = "main"

local BASE_URL = table.concat({
    "https://raw.githubusercontent.com",
    OWNER,
    REPOSITORY,
    BRANCH
}, "/")

local TEMP_MANIFEST = "/.craftbot-manifest.tmp"
local TEMP_SUFFIX = ".craftbot-download"
local SAFETY_MARGIN = 4096

local MANAGED_DIRECTORIES = {
    "/config",
    "/core",
    "/ui",
    "/packages",
}

local MANAGED_ROOT_FILES = {
    "/manager.lua",
    "/startup",
    "/catalog.lua",
    "/manifest.lua",
    "/update-manager.lua",
}

local function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

local function formatBytes(value)
    value = tonumber(value) or 0

    if value >= 1024 * 1024 then
        return string.format("%.2f Mo", value / (1024 * 1024))
    elseif value >= 1024 then
        return string.format("%.1f Ko", value / 1024)
    end

    return tostring(value) .. " octets"
end

local function pause()
    print("")
    print("Appuie sur une touche pour continuer.")
    os.pullEvent("key")
end

local function confirm(message, defaultYes)
    while true do
        write(message)

        if defaultYes then
            write(" [O/n] ")
        else
            write(" [o/N] ")
        end

        local answer = read():lower()

        if answer == "" then
            return defaultYes
        elseif answer == "o" or answer == "oui" or answer == "y" or answer == "yes" then
            return true
        elseif answer == "n" or answer == "non" or answer == "no" then
            return false
        end
    end
end

local function ensureParent(path)
    local parent = fs.getDir(path)

    if parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end
end

local function safeDelete(path)
    if fs.exists(path) then
        local ok, err = pcall(fs.delete, path)

        if not ok then
            return false, tostring(err)
        end
    end

    return true
end

local function cleanupTemporaryFiles(path)
    path = path or "/"

    if not fs.exists(path) or not fs.isDir(path) then
        return
    end

    for _, name in ipairs(fs.list(path)) do
        local child = fs.combine(path, name)

        if fs.isDir(child) then
            cleanupTemporaryFiles(child)
        elseif name:sub(-#TEMP_SUFFIX) == TEMP_SUFFIX then
            pcall(fs.delete, child)
        end
    end
end

local function stopInstallation(message)
    print("")
    printError("Installation interrompue.")
    printError(tostring(message or "Erreur inconnue"))
    print("")
    print("Espace libre : " .. formatBytes(fs.getFreeSpace("/")))
end

local function download(relativePath, destination)
    local url = BASE_URL .. "/" .. relativePath
    local temporaryPath = destination .. TEMP_SUFFIX

    write("Telechargement " .. relativePath .. " ... ")

    local response, requestError = http.get(url, nil, true)

    if not response then
        printError("ECHEC")
        return false, tostring(requestError or "Connexion impossible")
    end

    local data = response.readAll()
    response.close()

    if type(data) ~= "string" then
        printError("ECHEC")
        return false, "Reponse HTTP invalide"
    end

    if #data == 0 then
        printError("ECHEC")
        return false, "Le fichier telecharge est vide"
    end

    local freeSpace = fs.getFreeSpace("/")
    local oldSize = 0

    if fs.exists(destination) and not fs.isDir(destination) then
        oldSize = fs.getSize(destination)
    end

    local requiredExtra = math.max(0, #data - oldSize) + SAFETY_MARGIN

    if freeSpace < requiredExtra then
        printError("ESPACE INSUFFISANT")
        return false,
            "Fichier : " .. relativePath
            .. "\nTaille : " .. formatBytes(#data)
            .. "\nLibre : " .. formatBytes(freeSpace)
            .. "\nNecessaire : " .. formatBytes(requiredExtra)
    end

    ensureParent(destination)

    if fs.exists(temporaryPath) then
        fs.delete(temporaryPath)
    end

    local file = fs.open(temporaryPath, "w")

    if not file then
        printError("ECHEC")
        return false, "Impossible d'ouvrir " .. temporaryPath
    end

    local writeOk, writeError = pcall(function()
        file.write(data)
    end)

    file.close()

    if not writeOk then
        pcall(fs.delete, temporaryPath)
        printError("ECHEC")
        return false, tostring(writeError)
    end

    if fs.getSize(temporaryPath) ~= #data then
        local actualSize = fs.getSize(temporaryPath)
        pcall(fs.delete, temporaryPath)
        printError("ECHEC")
        return false,
            "Ecriture incomplete : "
            .. formatBytes(actualSize)
            .. " sur "
            .. formatBytes(#data)
    end

    if fs.exists(destination) then
        fs.delete(destination)
    end

    fs.move(temporaryPath, destination)

    print("OK")
    return true
end

local function loadManifest()
    local ok, err = download("manifest.lua", TEMP_MANIFEST)

    if not ok then
        return nil, err
    end

    local chunk, loadError = loadfile(TEMP_MANIFEST)

    if not chunk then
        return nil, "Impossible de charger le manifeste : " .. tostring(loadError)
    end

    local success, manifest = pcall(chunk)

    if not success then
        return nil, "Erreur dans le manifeste : " .. tostring(manifest)
    end

    if type(manifest) ~= "table" then
        return nil, "Le manifeste ne retourne pas une table"
    end

    if type(manifest.managerFiles) ~= "table" then
        return nil, "La liste managerFiles est absente"
    end

    if type(manifest.packages) ~= "table" then
        return nil, "La liste packages est absente"
    end

    return manifest
end

local function removePreviousManager()
    print("")
    print("Nettoyage de l'ancienne installation...")

    cleanupTemporaryFiles("/")

    for _, path in ipairs(MANAGED_DIRECTORIES) do
        local ok, err = safeDelete(path)

        if not ok then
            return false, path .. " : " .. tostring(err)
        end
    end

    for _, path in ipairs(MANAGED_ROOT_FILES) do
        local ok, err = safeDelete(path)

        if not ok then
            return false, path .. " : " .. tostring(err)
        end
    end

    print("Nettoyage termine.")
    print("Espace libre : " .. formatBytes(fs.getFreeSpace("/")))
    return true
end

local function installManagerFiles(manifest)
    print("")
    print("Installation du CraftBot Manager")
    print("--------------------------------")

    for _, relativePath in ipairs(manifest.managerFiles) do
        if type(relativePath) ~= "string" or relativePath == "" then
            return false, "Chemin Manager invalide dans le manifeste"
        end

        local ok, err = download(relativePath, "/" .. relativePath)

        if not ok then
            return false, err
        end
    end

    local optionalRootFiles = {
        "catalog.lua",
        "manifest.lua",
        "update-manager.lua",
    }

    for _, relativePath in ipairs(optionalRootFiles) do
        local ok, err = download(relativePath, "/" .. relativePath)

        if not ok then
            return false, err
        end
    end

    return true
end

local function installPackages(manifest)
    print("")
    print("Telechargement des packages")
    print("----------------------------")

    for _, packageData in ipairs(manifest.packages) do
        if type(packageData) ~= "table" then
            return false, "Entree package invalide dans le manifeste"
        end

        local folder = packageData.folder
        local files = packageData.files

        if type(folder) ~= "string" or folder == "" then
            return false, "Nom de package invalide"
        end

        if type(files) ~= "table" then
            return false, "Liste de fichiers absente pour " .. folder
        end

        print("")
        print("Package " .. folder .. " " .. tostring(packageData.version or ""))

        for _, relativePath in ipairs(files) do
            if type(relativePath) ~= "string" or relativePath == "" then
                return false, "Chemin invalide dans le package " .. folder
            end

            local source = "packages/" .. folder .. "/" .. relativePath
            local destination = "/" .. source

            local ok, err = download(source, destination)

            if not ok then
                return false, err
            end
        end
    end

    return true
end

local function writeRepositoryConfig()
    local path = "/config/repository.lua"
    ensureParent(path)

    local file = fs.open(path, "w")

    if not file then
        return false, "Impossible de creer " .. path
    end

    file.writeLine("return {")
    file.writeLine("    enabled = true,")
    file.writeLine('    owner = "' .. OWNER .. '",')
    file.writeLine('    repository = "' .. REPOSITORY .. '",')
    file.writeLine('    branch = "' .. BRANCH .. '"')
    file.writeLine("}")
    file.close()

    return true
end

local function main()
    clearScreen()

    print("======================================")
    print("       INSTALLATION CRAFTBOT")
    print("======================================")
    print("")
    print("Depot   : " .. OWNER .. "/" .. REPOSITORY)
    print("Branche : " .. BRANCH)
    print("Libre   : " .. formatBytes(fs.getFreeSpace("/")))
    print("")

    if not http or not http.get then
        stopInstallation("L'API HTTP de CC:Tweaked n'est pas disponible.")
        pause()
        return
    end

    cleanupTemporaryFiles("/")

    print("Recuperation du manifeste...")
    local manifest, manifestError = loadManifest()

    if not manifest then
        stopInstallation(manifestError)
        pause()
        return
    end

    print("")
    print("Manager : " .. tostring(manifest.managerVersion or "version inconnue"))
    print("Packages : " .. tostring(#manifest.packages))
    print("")

    local previousInstallation =
        fs.exists("/manager.lua")
        or fs.exists("/core")
        or fs.exists("/packages")

    if previousInstallation then
        print("Une installation CraftBot existe deja.")
        print("Une installation propre supprimera les anciens")
        print("fichiers du Manager et les packages locaux.")
        print("")
        print("Les dossiers /backups et /logs ne seront pas supprimes.")
        print("")

        if not confirm("Continuer avec une installation propre ?", false) then
            print("")
            print("Installation annulee.")
            safeDelete(TEMP_MANIFEST)
            return
        end

        local cleaned, cleanError = removePreviousManager()

        if not cleaned then
            stopInstallation(cleanError)
            pause()
            return
        end
    end

    local managerOk, managerError = installManagerFiles(manifest)

    if not managerOk then
        stopInstallation(managerError)
        pause()
        return
    end

    local packagesOk, packagesError = installPackages(manifest)

    if not packagesOk then
        stopInstallation(packagesError)
        print("")
        print("Conseil : supprime les anciens fichiers inutiles")
        print("ou installe CraftBot sur un ordinateur neuf.")
        pause()
        return
    end

    local configOk, configError = writeRepositoryConfig()

    if not configOk then
        stopInstallation(configError)
        pause()
        return
    end

    safeDelete(TEMP_MANIFEST)
    cleanupTemporaryFiles("/")

    print("")
    print("======================================")
    print("       INSTALLATION TERMINEE")
    print("======================================")
    print("")
    print("CraftBot Manager "
        .. tostring(manifest.managerVersion or "")
        .. " est installe.")
    print("Espace libre : " .. formatBytes(fs.getFreeSpace("/")))
    print("")

    if confirm("Redemarrer maintenant ?", true) then
        os.reboot()
    else
        print("")
        print("Lance 'reboot' pour demarrer CraftBot.")
    end
end

local ok, err = pcall(main)

if not ok then
    print("")
    printError("Erreur fatale de l'installateur :")
    printError(tostring(err))
    print("")
    print("Espace libre : " .. formatBytes(fs.getFreeSpace("/")))
end
