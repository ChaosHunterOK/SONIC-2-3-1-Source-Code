local ffi = require("ffi")
local discord = {}

local C = ffi.load("discord-rpc")
discord.C = C

ffi.cdef[[
    typedef struct DiscordRichPresence {
        const char* state;
        const char* details;
        int64_t startTimestamp;
        int64_t endTimestamp;
        const char* largeImageKey;
        const char* largeImageText;
        const char* smallImageKey;
        const char* smallImageText;
        const char* partyId;
        int partySize;
        int partyMax;
        const char* matchSecret;
        const char* joinSecret;
        const char* spectateSecret;
        unsigned int instance;
    } DiscordRichPresence;

    void Discord_Initialize(const char* applicationId, void* handlers, int autoRegister, const char* optionalSteamId);
    void Discord_Shutdown();
    void Discord_UpdatePresence(const DiscordRichPresence* presence);
    void Discord_RunCallbacks();
]]
local presence = ffi.new("DiscordRichPresence")

local function setField(field, value, default)
    presence[field] = value ~= nil and value or default
end

function discord.initialize(appId)
    C.Discord_Initialize(appId, nil, 1, nil)
end

function discord.updatePresence(data)
    setField("state", data.state, nil)
    setField("details", data.details, nil)
    setField("startTimestamp", data.startTimestamp, 0)
    setField("endTimestamp", data.endTimestamp, 0)
    setField("largeImageKey", data.largeImageKey, nil)
    setField("largeImageText", data.largeImageText, nil)
    setField("smallImageKey", data.smallImageKey, nil)
    setField("smallImageText", data.smallImageText, nil)
    setField("partyId", data.partyId, nil)
    setField("partySize", data.partySize, 0)
    setField("partyMax", data.partyMax, 0)
    setField("matchSecret", data.matchSecret, nil)
    setField("joinSecret", data.joinSecret, nil)
    setField("spectateSecret", data.spectateSecret, nil)
    setField("instance", data.instance, 0)

    C.Discord_UpdatePresence(presence)
end

function discord.runCallbacks()
    C.Discord_RunCallbacks()
end

function discord.shutdown()
    C.Discord_Shutdown()
end

return discord