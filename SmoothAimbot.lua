local imgui = require 'imgui'
local encoding = require 'encoding'
local key = require('vkeys')
local ffi = require('ffi')
encoding.default = 'CP1251'
u8 = encoding.UTF8

local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

function GetBodyPartCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

local fontsize = nil

function imgui.BeforeDrawFrame()
    if fontsize == nil then
        fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 35.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

Speed = imgui.ImFloat(0)
Dist = imgui.ImFloat(0)
Fov = imgui.ImFloat(0)

local cbz1 = imgui.ImBool(false)
local cbz2 = imgui.ImBool(false)
local cbz3 = imgui.ImBool(false)
local cbz4 = imgui.ImBool(false)
local cbz5 = imgui.ImBool(false)

local aiming = 8

local windows = imgui.ImBool(false)

function main()
    repeat wait(0) until isSampAvailable()
    sampRegisterChatCommand('saim', function()
        windows.v = not windows.v
		imgui.Process = windows.v
    end)
    lua_thread.create(SmoothAimBot)
    while true do wait(0)
        if not windows.v then imgui.Process = false end
        if cbz1.v then
            aiming = 8
        end
        if cbz2.v then
            aiming = 3
        end
        if cbz3.v then
            aiming = 42
        end
        if cbz4.v then
            aiming = 54
        end
    end
end

function imgui.OnDrawFrame()
    if windows.v then
        imgui.SetNextWindowPos(imgui.ImVec2(350.0, 250.0), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(258.0, 345.0), imgui.Cond.FirstUseEver)
        imgui.Begin('', windows, imgui.WindowFlags.NoResize + imgui.WindowFlags.ShowBorders)

        imgui.Text("")

        imgui.PushFont(fontsize)
		imgui.CenterText("Smooth AimBot")
		imgui.PopFont()

        imgui.CenterText("by [w0te]")

        imgui.Separator()

        imgui.Text("")

        imgui.BeginChild("BeginChild", imgui.ImVec2(241, 210), true)

        imgui.CenterText("Settings")

        imgui.Separator()

        imgui.BeginGroup()
        imgui.PushItemWidth(170.0)
		imgui.SliderFloat("Speed", Speed, 0.0, 50.0, '%.1f')
		imgui.PopItemWidth()

        imgui.PushItemWidth(170.0)
		imgui.SliderFloat("Dist", Dist, 0.0, 100.0, '%.1f')
		imgui.PopItemWidth()

        imgui.PushItemWidth(170.0)
		imgui.SliderFloat("Fov", Fov, 0.0, 100.0, '%.1f')
		imgui.PopItemWidth()
        imgui.EndGroup()

        imgui.BeginGroup()
        if imgui.Checkbox('Aiming Head', cbz1) then
        end

        if imgui.Checkbox('Aiming Tors', cbz2) then
        end

        if imgui.Checkbox('Aiming Foot', cbz3) then
        end

        if imgui.Checkbox('Aiming Leg', cbz4) then
        end
        imgui.EndGroup()

        imgui.SameLine()

        if imgui.Checkbox('Enabled AimBot', cbz5) then
        end
        imgui.EndChild()

        imgui.End()
    end
end

function fix(angle)
    if angle > math.pi then
        angle = angle - (math.pi * 2)
    elseif angle < -math.pi then
        angle = angle + (math.pi * 2)
    end
    return angle
end

function GetNearestPed(fov)
    local maxDistance = Dist.v
    local nearestPED = -1
    for i = 0, sampGetMaxPlayerId(true) do
        if sampIsPlayerConnected(i) then
            local find, handle = sampGetCharHandleBySampPlayerId(i)
            if find then
                if isCharOnScreen(handle) then
                    if not isCharDead(handle) then
                        local _, currentID = sampGetPlayerIdByCharHandle(PLAYER_PED)
                        local enPos = {GetBodyPartCoordinates(aiming, handle)}
                        local myPos = {getActiveCameraCoordinates()}
                        local vector = {myPos[1] - enPos[1], myPos[2] - enPos[2], myPos[3] - enPos[3]}
                        if isWidescreenOnInOptions() then coefficentZ = 0.0778 else coefficentZ = 0.103 end
                        local angle = {(math.atan2(vector[2], vector[1]) + 0.04253), (math.atan2((math.sqrt((math.pow(vector[1], 2) + math.pow(vector[2], 2)))), vector[3]) - math.pi / 2 - coefficentZ)}
                        local view = {fix(representIntAsFloat(readMemory(0xB6F258, 4, false))), fix(representIntAsFloat(readMemory(0xB6F248, 4, false)))}
                        local distance = math.sqrt((math.pow(angle[1] - view[1], 2) + math.pow(angle[2] - view[2], 2))) * 57.2957795131
                        if distance > fov then check = true else check = false end
                        if not check then
                            local myPos = {getCharCoordinates(PLAYER_PED)}
                            local distance = math.sqrt((math.pow((enPos[1] - myPos[1]), 2) + math.pow((enPos[2] - myPos[2]), 2) + math.pow((enPos[3] - myPos[3]), 2)))
                            if (distance < maxDistance) then
                                nearestPED = handle
                                maxDistance = distance
                            end
                        end
                    end
                end
            end
        end
    end
    return nearestPED
end

function SmoothAimBot()
    if cbz5.v and isKeyDown(key.VK_RBUTTON) and isKeyDown(key.VK_LBUTTON) then
        local handle = GetNearestPed(Fov.v)
        if handle ~= -1 then
            local myPos = {getActiveCameraCoordinates()}
            local enPos = {GetBodyPartCoordinates(aiming, handle)} -- mantendo a altura original do corpo
            local vector = {myPos[1] - enPos[1], myPos[2] - enPos[2], myPos[3] - enPos[3]}
            if isWidescreenOnInOptions() then 
                coefficentZ = 0.0778 
            else 
                coefficentZ = 0.103 
            end

            -- Calcula os ângulos para a mira
            local angle = {
                (math.atan2(vector[2], vector[1]) + 0.04253), 
                (math.atan2((math.sqrt((math.pow(vector[1], 2) + math.pow(vector[2], 2)))), vector[3]) - math.pi / 2 - coefficentZ)
            }

            -- Obtém a visão atual da câmera
            local view = {
                fix(representIntAsFloat(readMemory(0xB6F258, 4, false))), 
                fix(representIntAsFloat(readMemory(0xB6F248, 4, false)))
            }

            -- Calcula a diferença entre o ângulo desejado e o ângulo atual
            local difference = {angle[1] - view[1], angle[2] - view[2]}
            
            -- Aumenta a suavização para um movimento mais gradual
            local smoothFactor = Speed.v * 5  -- Ajuste este valor para aumentar a suavidade
            local smooth = {difference[1] / smoothFactor, difference[2] / smoothFactor}
            
            -- Define a nova posição da câmera
            setCameraPositionUnfixed((view[2] + smooth[2]), (view[1] + smooth[1]))
        end
    end
    return false
end



imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 16.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 2.0
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0

    colors[clr.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
    colors[clr.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
    colors[clr.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)