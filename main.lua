local hp = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or _senv.request or request or Https and Https.request
local httpservice = game:GetService("HttpService")

if isfolder("PianoAutoplayer") == false then
    makefolder("PianoAutoplayer")
end

if isfile("PianoAutoplayer/songs.txt") == false then
    writefile("PianoAutoplayer/songs.txt", "{}")
end

getgenv().hasSongAdded = false

getgenv().config = {
    enabled = true,
    delay = 0.2,
    noteLength = 0.01,
    selectedSong = nil,
    songToRemove = nil
}

getgenv().songAdd = {
    songName = nil,
    songNotes = nil
}

getgenv().songs = httpservice:JSONDecode(readfile("PianoAutoplayer/songs.txt"))

for i,v in pairs(songs) do
    print("Loaded " .. v.songName)
end

getgenv().AsciiKeys = {
	['a'] = 0x41,
	['b'] = 0x42,
	['c'] = 0x43,
	['d'] = 0x44,
	['e'] = 0x45,
	['f'] = 0x46,
	['g'] = 0x47,
	['h'] = 0x48,
	['i'] = 0x49,
	['j'] = 0x4A,
	['k'] = 0x4B,
	['l'] = 0x4C,
	['m'] = 0x4D,
	['n'] = 0x4E,
	['o'] = 0x4F,
	['p'] = 0x50,
	['q'] = 0x51,
	['r'] = 0x52,
	['s'] = 0x53,
	['t'] = 0x54,
	['u'] = 0x55,
	['v'] = 0x56,
	['w'] = 0x57,
	['x'] = 0x58,
	['y'] = 0x59,
	['z'] = 0x5A,
	['0'] = 0x30,
	['1'] = 0x31,
	['2'] = 0x32,
	['3'] = 0x33,
	['4'] = 0x34,
	['5'] = 0x35,
	['6'] = 0x36,
	['7'] = 0x37,
	['8'] = 0x38,
	['9'] = 0x39,
	['!'] = 0x31,
	['@'] = 0x32,
	['$'] = 0x34,
	['%'] = 0x35,
	['^'] = 0x36,
	['('] = 0x39
}

function pressKey(key)
    if key == key:lower() then
        keypress(AsciiKeys[key:lower()])
        task.wait(config.noteLength)
        keyrelease(AsciiKeys[key:lower()])
    else
        keypress(0xA0)
        keypress(AsciiKeys[key:lower()])
        task.wait(config.noteLength)
        keyrelease(AsciiKeys[key:lower()])
        keyrelease(0xA0)
    end
end

function parseSong(notes)

    finalNotesList = {}
    removeIndexs = {}
    
    -- notes = notes:gsub("%|", "")
    notesList = string.split(notes, "")
    
    
    for i, note in pairs(notesList) do
        if table.find(removeIndexs, i) == nil then
            if note == "[" then
    
                -- print("Index:", i, "Note:", note)
    
                curIndex = i
                curNote = notesList[i]
    
                while curNote ~= "]" and task.wait() do
                    curIndex = curIndex + 1
                    curNote = notesList[curIndex]
    
                end
                -- print(notesList[curIndex], curIndex)
                
    
                -- important one 
                -- print(string.sub(notes, i + 1, curIndex - 1), string.sub(notes, i, curIndex))
    
                table.insert(finalNotesList, string.sub(notes, i + 1, curIndex - 1))
    
                for x=0, #string.sub(notes, i, curIndex) - 1 do
                    table.insert(removeIndexs, (x + i))
                end
            else
                table.insert(finalNotesList, note)
            end
        end
    end
    
    return finalNotesList
end

function playSong(notes)
    for i,v in pairs(notes) do
        if v ~= "|" and v ~= " " then
            if #v > 1 then
                for _, char in pairs(string.split(v, "")) do
                    
                    -- print(char, AsciiKeys[char:lower()])
                    
                    xpcall(function()
                        pressKey(char)
                    end, function()

                        -- print("Failed Note:", char)
                    end)
                    
                        
                end
            else

                xpcall(function()
                    pressKey(v)
                end, function()

                    -- print("Failed Note:", v)
                end)
                    

            end
        end

        if v == "|" then
            task.wait(config.delay + (config.delay * 0.35))
        elseif v == " " then
            task.wait(config.delay + (config.delay * 0.25))
        elseif v == "-" then
            task.wait(config.delay + (config.delay * 0.1))
        else
            task.wait(config.delay)
        end   


        if config.enabled == false then break end;
    end
end

function refreshList(list)
    local songsToAdd = {}
    for i,v in pairs(songs) do
        table.insert(songsToAdd, v.songName)
    end

    list:Refresh(songsToAdd, true)
end

-------------- Gui

local SolarisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stebulous/solaris-ui-lib/main/source.lua"))()

local win = SolarisLib:New({
  Name = "Piano Autoplayer - Sw1ndler",
  FolderToSave = "PianoAutoplayer"
})

local mainTab = win:Tab("Song AutoPlayer")

local settingsTab = win:Tab("Settings")

local songPlaying = mainTab:Section("Main")

local songParsing = mainTab:Section("Song Proccessing")

local settingsSection = settingsTab:Section("Settings")


local dropdownList
if #songs > 0 then
    dropdownList = {}
    for i,v in pairs(songs) do
        table.insert(dropdownList, v.songName)
    end
else
    dropdownList = {"Add some songs to play in the section below", '(or head into the settings tab and click the "Load Presets" button)'}
end

local songDropdown = songPlaying:Dropdown("Song List", dropdownList,"","Dropdown", function(t)
  config.selectedSong = t
end)


delaySlider = songPlaying:Slider("Delay Between Notes", 0,1,0.2,0.01,"", function(t)
  config.delay = t
end)

lengthSlider = songPlaying:Slider("Note Length", 0,1,0,0.01,"", function(t)
  config.noteLength = t
end)

songPlaying:Toggle("Enabled", false,"", function(t)
    config.enabled = t

    if t == true then
        if config.selectedSong == nil then
            SolarisLib:Notification("Warning", "No song selected!")
            return
        end

        local curSong = nil
        for i,v in pairs(songs) do
            if v.songName == config.selectedSong then
                curSong = v
            end
        end

        playSong(curSong.parsed)
    end
end)


getgenv().songAdd = {
    songName = nil,
    songNotes = nil
}


songParsing:Textbox("Song Name", false, function(t)
  songAdd.songName = t
end)

songParsing:Textbox("Song Notes", false, function(t)
  songAdd.songNotes = t
end)

songParsing:Button("Add song to list", function()

    if songAdd.songName == "" or songAdd.songName == nil or songAdd.songNotes == "" or songAdd.songNotes == nil then
        SolarisLib:Notification("Warning", "One or more inputs were invalid")
        return
    end

    parsingLabel:Set("Processing Song ...")

    local parsedNotes = parseSong(songAdd.songNotes)

    
    table.insert(songs, {
        songName = songAdd.songName,
        notes = songAdd.songNotes,
        parsed = parsedNotes
    })

    writefile("PianoAutoplayer/songs.txt", httpservice:JSONEncode(songs))


    refreshList(songDropdown)
    refreshList(removeSongDropdown)

    task.spawn(function()
        parsingLabel:Set("Finished processing your song!")
        wait(8)
        parsingLabel:Set("Insert a song above to start processing it")
    end)

end)

parsingLabel = songParsing:Label("Insert a song above to start processing it")

removeList = {}
for i,v in pairs(songs) do
    table.insert(removeList, v.songName)
end

settingsSection:Button("Load Preset Songs", function()
    presetSongs = hp(
        {
            Url = "https://raw.githubusercontent.com/OptioniaI/PianoAutoPlayerPresets/main/main.lua",
            Method = "GET"
        }
    )

    presetSongs = presetSongs.Body
    presetSongs = game:GetService("HttpService"):JSONDecode(presetSongs)
    presetSongs = presetSongs[1]

    songs = presetSongs
    writefile("PianoAutoplayer/songs.txt", httpservice:JSONEncode(presetSongs))

    refreshList(songDropdown)
    refreshList(removeSongDropdown)
end)

removeSongDropdown = settingsSection:Dropdown("Song to Remove", removeList,"","", function(t)
  config.songToRemove = t
end)

settingsSection:Button("Remove Song", function()

    for i,v in pairs(songs) do
        if v.songName == config.songToRemove then
            table.remove(songs, i)
        end
    end

    refreshList(songDropdown)
    refreshList(removeSongDropdown)
    writefile("PianoAutoplayer/songs.txt", httpservice:JSONEncode(songs))
end)

settingsSection:Button("Clear Songs", function()
    writefile("PianoAutoplayer/songs.txt", "{}")
    songs = {}
    songDropdown:Refresh({}, true)
end)

settingsSection:Textbox("Custom Delay", false, function(t)
    config.delay = tonumber(t)
    delaySlider:Set(tonumber(t))
end)

settingsSection:Textbox("Custom Note Length", false, function(t)
    config.noteLength = tonumber(t)
    lengthSlider:Set(tonumber(t))
end)
