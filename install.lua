-- ============================================================
-- CraftBot Manager - Installateur GitHub
-- ============================================================

local OWNER = "BemJ77"
local REPOSITORY = "CraftBot"
local BRANCH = "main"

local BASE_URL =
    "https://raw.githubusercontent.com/"
    .. OWNER
    .. "/"
    .. REPOSITORY
    .. "/"
    .. BRANCH

local MANIFEST_PATH = "/downloads/github-manifest.lua"

------------------------------------------------------------
-- Vérifications
------------------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("======================================")
print("       INSTALLATION CRAFTBOT")
print("======================================")
print("")
print("Depot   : " .. OWNER .. "/" .. REPOSITORY)
print("Branche : " .. BRANCH)
print("")

if not http or not http.get then
    printError("L'API HTTP n'est pas disponible.")
    printError("Verifie la configuration de CC:Tweaked.")
    return
end

------------------------------------------------------------
-- Fonctions utilitaires
------------------------------------------------------------

local function createParentDirectory(path)
    local directory = fs.getDir(path)

    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

local function download(relativePath, destination)
    write("Telechargement " .. relativePath .. " ... ")

    local url = BASE_URL .. "/" .. relativePath
    local response, errorMessage = http.get(url, nil, true)

    if not response then
        printError("ECHEC")
        return false, tostring(
            errorMessage or "Telechargement impossible"
        )
    end

    local data = response.readAll()
    response.close()

    if not data then
        printError("ECHEC")
        return false, "Le fichier telecharge est vide"
    end

    createParentDirectory(destination)

    local temporaryPath = destination .. ".download"

    if fs.exists(temporaryPath) then
        fs.delete(temporaryPath)
    end

    local file = fs.open(temporaryPath, "wb")

    if not file then
        printError("ECHEC")
        return false,
            "Impossible d'ecrire le fichier " .. temporaryPath
    end

    file.write(data)
    file.close()

    if fs.exists(destination) then
        fs.delete(destination)
    end

    fs.move(temporaryPath, destination)

    print("OK")
    return true
end

local function stopInstallation(message)
    print("")
    printError("Installation interrompue.")
    printError(tostring(message))
    print("")
end

------------------------------------------------------------
-- Téléchargement du manifeste
------------------------------------------------------------

print("Recuperation du manifeste...")
print("")

local manifestDownloaded, manifestDownloadError =
    download("manifest.lua", MANIFEST_PATH)

if not manifestDownloaded then
    stopInstallation(manifestDownloadError)
    return
end

local manifestChunk, manifestLoadError =
    loadfile(MANIFEST_PATH)

if not manifestChunk then
    stopInstallation(
        "Impossible de charger le manifeste : "
        .. tostring(manifestLoadError)
    )
    return
end

local manifestSuccess, manifest =
    pcall(manifestChunk)

if not manifestSuccess then
    stopInstallation(
        "Erreur dans le manifeste : "
        .. tostring(manifest)
    )
    return
end

if type(manifest) ~= "table" then
    stopInstallation("Le manifeste GitHub est invalide.")
    return
end

------------------------------------------------------------
-- Téléchargement du Manager
------------------------------------------------------------

print("")
print("Installation du CraftBot Manager...")
print("")

for _, relativePath in ipairs(manifest.managerFiles or {}) do
    local success, errorMessage =
        download(relativePath, "/" .. relativePath)

    if not success then
        stopInstallation(
            relativePath .. " : " .. tostring(errorMessage)
        )
        return
    end
end

------------------------------------------------------------
-- Téléchargement des packages
------------------------------------------------------------

print("")
print("Telechargement des packages...")
print("")

for _, packageData in ipairs(manifest.packages or {}) do
    if type(packageData) == "table"
        and type(packageData.folder) == "string" then

        print(
            "Package "
            .. packageData.folder
            .. " "
            .. tostring(packageData.version or "")
        )

        for _, relativePath in
            ipairs(packageData.files or {}) do

            local source =
                "packages/"
                .. packageData.folder
                .. "/"
                .. relativePath

            local destination = "/" .. source

            local success, errorMessage =
                download(source, destination)

            if not success then
                stopInstallation(
                    source .. " : " .. tostring(errorMessage)
                )
                return
            end
        end

        print("")
    end
end

------------------------------------------------------------
-- Enregistrement du dépôt
------------------------------------------------------------

local repositoryConfigPath = "/config/repository.lua"

createParentDirectory(repositoryConfigPath)

local configFile =
    fs.open(repositoryConfigPath, "w")

if not configFile then
    stopInstallation(
        "Impossible de creer "
        .. repositoryConfigPath
    )
    return
end

configFile.writeLine("return {")
configFile.writeLine("    enabled = true,")
configFile.writeLine('    owner = "' .. OWNER .. '",')
configFile.writeLine(
    '    repository = "' .. REPOSITORY .. '",'
)
configFile.writeLine('    branch = "' .. BRANCH .. '"')
configFile.writeLine("}")

configFile.close()

------------------------------------------------------------
-- Fin
------------------------------------------------------------

if fs.exists(MANIFEST_PATH) then
    fs.delete(MANIFEST_PATH)
end

print("")
print("======================================")
print("       INSTALLATION TERMINEE")
print("======================================")
print("")
print(
    "CraftBot Manager "
    .. tostring(manifest.managerVersion or "")
    .. " est installe."
)
print("")
print("Redemarrage dans 3 secondes...")

sleep(3)
os.reboot()
