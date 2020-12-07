--- === BingDaily ===
---
--- Use Bing daily picture as your wallpaper, automatically.
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/BingDaily.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/BingDaily.spoon.zip)

local obj={}
obj.__index = obj

-- Metadata
obj.name = "BingDaily"
obj.version = "1.0"
obj.author = "ashfinal <ashfinal@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local function curl_callback(exitCode, stdOut, stdErr)
    if exitCode == 0 then
        obj.task = nil
        local filename = hs.http.urlParts(obj.full_url).lastPathComponent
        local localpath = obj.dir .. filename
        hs.screen.mainScreen():desktopImageURL("file://" .. localpath)
        -- delete file
        if obj.last_pic then

        end
        obj.last_pic = filename
    else
        print(stdOut, stdErr)
    end
end

local function bingRequest()
    local user_agent_str = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.1.1 Safari/603.2.4"
    local json_req_url = "https://bing.ioliu.cn/v1/?type=json"
    hs.http.asyncGet(json_req_url, {["User-Agent"]=user_agent_str}, function(stat,body,header)
        if stat == 200 then
            if pcall(function() hs.json.decode(body) end) then
                local decode_data = hs.json.decode(body)
                local pic_url = decode_data.data.url
                local pic_name = hs.http.urlParts(pic_url).lastPathComponent
                if obj.last_pic ~= pic_name then
                    obj.full_url = pic_url
                    if obj.task then
                        obj.task:terminate()
                        obj.task = nil
                    end
                    local localpath = obj.dir .. pic_name
                    obj.task = hs.task.new("/usr/bin/curl", curl_callback, {"-A", user_agent_str, obj.full_url, "-o", localpath})
                    obj.task:start()
                end
            end
        else
            print("Bing URL request failed!")
        end
    end)
end

function obj:init()
    obj.dir = os.getenv("HOME") .. "/.hammerspoon/desktop/"
    hs.fs.mkdir(obj.dir)
    if obj.timer == nil then
        obj.timer = hs.timer.doEvery(3*60*60, function() bingRequest() end)
        obj.timer:setNextTrigger(5)
    else
        obj.timer:start()
    end
end

return obj
