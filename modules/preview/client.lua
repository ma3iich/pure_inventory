if not lib then return end

-- 3D character in the middle of the inventory.
-- A local copy of the player's ped (never networked) is drawn in front of the camera every frame, at a fixed
-- place on screen. While the inventory is open, a script camera copies the game camera and follows the
-- player (or his vehicle): the copy cannot shake, grow or leave the screen when the player moves.

local settings = shared.preview

local Preview = { active = false }

if not settings.Enabled then
    Preview.start, Preview.stop, Preview.refresh = function() end, function() end, function() end
    return Preview
end

local clone
local renderId = 0
local previewCam

local IK_FROZEN = 4 + 8 + 16 -- no head / torso IK: the copy does not look at the players around

local function playPose(ped)
    local pose = settings.Pose
    local anim = pose and (IsPedMale(ped) and pose.male or pose.female)

    SetPedCanHeadIk(ped, false)

    if not anim or not anim.dict or not anim.anim then return end

    local function play()
        TaskPlayAnim(ped, anim.dict, anim.anim, 1000.0, -8.0, -1, 1, pose.phase or 0.0, true, IK_FROZEN, false)
    end

    if HasAnimDictLoaded(anim.dict) then return play() end

    RequestAnimDict(anim.dict)

    CreateThread(function()
        local timeout = GetGameTimer() + 1000

        while not HasAnimDictLoaded(anim.dict) and GetGameTimer() < timeout do Wait(0) end

        if HasAnimDictLoaded(anim.dict) and DoesEntityExist(ped) and ped == clone then
            play()
        end
    end)
end

local function createClone()
    local source = cache.ped
    local model = GetEntityModel(source)
    local coords = GetEntityCoords(source)

    if not HasModelLoaded(model) then
        RequestModel(model)
        local timeout = GetGameTimer() + 2000
        while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    end

    local ped = CreatePed(26, model, coords.x, coords.y, coords.z, 0.0, false, false)

    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    NetworkSetEntityInvisibleToNetwork(ped, false)
    ClonePedToTarget(source, ped)
    SetEntityCanBeDamaged(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    ClearPedTasksImmediately(ped)
    SetPedCanRagdoll(ped, false)
    SetPedCanPlayAmbientAnims(ped, false)
    SetPedCanPlayAmbientBaseAnims(ped, false)
    SetPedKeepTask(ped, true)
    SetModelAsNoLongerNeeded(model)

    playPose(ped)

    return ped
end

local abs = math.abs
local POS_TOLERANCE, DIR_TOLERANCE = 0.0005, 0.0001

-- SetEntityMatrix is the costly call of the loop: the matrix is only written when it changed.
local function writeMatrix(ped, force, fx, fy, rx, ry, uz, px, py, pz)
    if not force then
        local f, r, u, p = GetEntityMatrix(ped)

        if abs(p.x - px) <= POS_TOLERANCE and abs(p.y - py) <= POS_TOLERANCE and abs(p.z - pz) <= POS_TOLERANCE
            and abs(f.x - fx) <= DIR_TOLERANCE and abs(f.y - fy) <= DIR_TOLERANCE and abs(f.z) <= DIR_TOLERANCE
            and abs(r.x - rx) <= DIR_TOLERANCE and abs(r.y - ry) <= DIR_TOLERANCE and abs(r.z) <= DIR_TOLERANCE
            and abs(u.x) <= DIR_TOLERANCE and abs(u.y) <= DIR_TOLERANCE and abs(u.z - uz) <= DIR_TOLERANCE then
            return
        end
    end

    SetEntityMatrix(ped, fx, fy, 0.0, rx, ry, 0.0, 0.0, 0.0, uz, px, py, pz)
end

local function takeCamera(pos, rot, fov)
    -- never take the screen from another resource that renders its own camera
    if previewCam or GetRenderingCam() ~= -1 then return end

    previewCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', false)
    SetCamCoord(previewCam, pos.x, pos.y, pos.z)
    SetCamRot(previewCam, rot.x, rot.y, rot.z, 2)
    SetCamFov(previewCam, fov)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 0, true, true)
end

local function releaseCamera()
    if not previewCam then return end
    if GetRenderingCam() == previewCam then RenderScriptCams(false, false, 0, true, true) end

    DestroyCam(previewCam, false)
    previewCam = nil
end

local function playerAnchor()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    return vehicle ~= 0 and vehicle or cache.ped
end

local function cameraAxes(rot)
    local p, h = math.rad(rot.x), math.rad(rot.z)
    local cp, sp, ch, sh = math.cos(p), math.sin(p), math.cos(h), math.sin(h)
    return vector3(-sh * cp, ch * cp, sp), vector3(ch, sh, 0.0), vector3(sh * sp, -ch * sp, cp)
end

local function screenRay(r, sx, sy)
    local d = r.forward + r.right * ((2.0 * sx - 1.0) * r.tanH) + r.up * ((1.0 - 2.0 * sy) * r.tanV)
    return d / #d
end

-- mouse: rotation and zoom wanted, and zoom shown (slides to the wanted value)
local view = { rotation = 0.0, zoom = 1.0, x = 0.5, y = 0.45 }
local shown = { zoom = 1.0, x = 0.5, y = 0.45 }

local function approach(a, b, step)
    local d = b - a
    if abs(d) <= step then return b end
    return a + d * 0.25
end

local FIRST_PERSON, THIRD_PERSON = 4, 1
local changedViewContext

local function leaveFirstPerson()
    if changedViewContext or not settings.LeaveFirstPerson then return end

    local context = GetCamActiveViewModeContext()

    if GetCamViewModeForContext(context) == FIRST_PERSON then
        SetCamViewModeForContext(context, THIRD_PERSON)
        changedViewContext = context
    end
end

local function backToFirstPerson()
    if not changedViewContext then return end

    SetCamViewModeForContext(changedViewContext, FIRST_PERSON)
    changedViewContext = nil
end

local function startRender()
    Preview.active = true
    renderId += 1

    local myId = renderId
    local screenX, screenY = settings.ScreenX or 0.5, settings.ScreenY or 0.45

    leaveFirstPerson()

    view.rotation, view.zoom, view.x, view.y = 0.0, 1.0, screenX, screenY
    shown.zoom, shown.x, shown.y = 1.0, screenX, screenY

    CreateThread(function()
        local upZ = 0.45
        local lastHeading
        local light = settings.Light
        local tanRef = settings.FovReference and math.tan(math.rad(settings.FovReference) / 2.0)
        local r = {}

        SetGameplayCamRelativePitch(0.0, 1.0)
        DisableIdleCamera(true)
        Wait(0)

        -- calibration: near plane and screen scale measured on the game camera
        local near, corrH, corrV = 0.0, 1.0, 1.0

        do
            local w, n = GetWorldCoordFromScreenCoord(screenX, screenY)
            local d = w - GetGameplayCamCoord()
            near = math.max(0.0, math.min(1.0, d.x * n.x + d.y * n.y + d.z * n.z))

            local fwd, right, up = cameraAxes(GetGameplayCamRot(2))
            local tv = math.tan(math.rad(GetGameplayCamFov()) / 2.0)
            local _, nH = GetWorldCoordFromScreenCoord(1.0, 0.5)
            local _, nV = GetWorldCoordFromScreenCoord(0.5, 0.0)
            local fH, fV = nH.x * fwd.x + nH.y * fwd.y + nH.z * fwd.z, nV.x * fwd.x + nV.y * fwd.y + nV.z * fwd.z

            if fH > 0.01 and fV > 0.01 and tv > 0.0 then
                local h = (nH.x * right.x + nH.y * right.y + nH.z * right.z) / fH / (tv * GetAspectRatio(false))
                local v = (nV.x * up.x + nV.y * up.y + nV.z * up.z) / fV / tv

                if h > 0.5 and h < 2.0 and v > 0.5 and v < 2.0 then corrH, corrV = h, v end
            end
        end

        if settings.FixedCamera ~= false then
            takeCamera(GetGameplayCamCoord(), GetGameplayCamRot(2), GetGameplayCamFov())
        end

        local anchor, anchorPos

        local function frame()
            SetGameplayCamRelativePitch(0.0, 1.0)

            local camPos, camRot, fov

            if previewCam then
                -- the game camera is computed after the scripts: it is one frame late. The anchor movement
                -- since the last frame is added so the copy stays at the same place on screen.
                local a = playerAnchor()
                local pa = GetEntityCoords(a)
                camPos, camRot, fov = GetGameplayCamCoord(), GetGameplayCamRot(2), GetGameplayCamFov()

                if a == anchor and anchorPos then camPos = camPos + (pa - anchorPos) end

                anchor, anchorPos = a, pa
                SetCamCoord(previewCam, camPos.x, camPos.y, camPos.z)
                SetCamRot(previewCam, camRot.x, camRot.y, camRot.z, 2)
                SetCamFov(previewCam, fov)
            else
                camPos, camRot, fov = GetFinalRenderedCamCoord(), GetFinalRenderedCamRot(2), GetFinalRenderedCamFov()
            end

            r.pos = camPos
            r.forward, r.right, r.up = cameraAxes(camRot)

            local tanFov = math.tan(math.rad(fov) / 2.0)
            r.tanV = tanFov * corrV
            r.tanH = tanFov * GetAspectRatio(false) * corrH

            -- same size on screen whatever the field of view
            local depth = near + (settings.Depth or 1.5) * (tanRef and tanRef / tanFov or 1.0)

            shown.zoom = approach(shown.zoom, view.zoom, 0.0005)
            shown.x = approach(shown.x, view.x, 0.0005)
            shown.y = approach(shown.y, view.y, 0.0005)

            local ray = screenRay(r, shown.x, shown.y)
            local target = camPos + ray * depth

            if IsScreenblurFadeRunning() then DisableScreenblurFade() end

            local heading = camRot.z + 180.0 + view.rotation
            local newHeading = heading ~= lastHeading

            if newHeading then
                SetEntityHeading(clone, heading)
                lastHeading = heading
            end

            -- the mouse moves the copy, not the game camera
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)

            local k = (settings.Scale or 0.85) * shown.zoom
            local e = upZ * k
            local rad = math.rad(heading)
            local s, c = math.sin(rad), math.cos(rad)

            writeMatrix(clone, newHeading, -s * e, c * e, c * e, s * e, e, target.x, target.y, target.z)

            if light then
                local p = target - ray * light.front
                DrawLightWithRange(p.x, p.y, p.z + light.up * k, light.r, light.g, light.b, light.range, light.intensity)
            end
        end

        local closedSince

        while Preview.active and renderId == myId and clone and DoesEntityExist(clone) do
            -- safety: the page normally stops the preview when the inventory closes
            if not LocalPlayer.state.invOpen then
                closedSince = closedSince or GetGameTimer()
                if GetGameTimer() - closedSince > 1000 then break end
            else
                closedSince = nil
            end

            local ok, err = pcall(frame)

            if not ok then
                lib.print.error(err)
                break
            end

            Wait(0)
        end

        -- an error, a stop or a closed inventory always removes the copy and gives the camera back
        if renderId == myId then
            if Preview.active then Preview.stop() else releaseCamera() end
        end
    end)
end

function Preview.stop(keepView)
    if not Preview.active then return end

    Preview.active = false
    renderId += 1

    if clone and DoesEntityExist(clone) then DeleteEntity(clone) end

    clone = nil
    releaseCamera()

    if not keepView then backToFirstPerson() end
end

function Preview.start()
    if IsScreenblurFadeRunning() then DisableScreenblurFade() end
    if Preview.active then Preview.stop(true) end

    clone = createClone()
    startRender()
end

-- copies the clothes of the player on the 3D copy (after a piece is put on / taken off)
function Preview.refresh(delay)
    SetTimeout(delay or 150, function()
        if Preview.active and clone and DoesEntityExist(clone) then
            ClonePedToTarget(cache.ped, clone)
        end
    end)
end

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

RegisterNUICallback('previewRotate', function(data, cb)
    cb(1)

    local dx = type(data) == 'table' and tonumber(data.dx)
    if not Preview.active or not dx or dx ~= dx then return end

    view.rotation = (view.rotation + clamp(dx, -1.0, 1.0) * 360.0) % 360.0
end)

RegisterNUICallback('previewZoom', function(data, cb)
    cb(1)

    if not Preview.active or type(data) ~= 'table' then return end

    local x, y = tonumber(data.x), tonumber(data.y)
    if not x or not y or x ~= x or y ~= y then return end

    x, y = clamp(x, 0.0, 1.0), clamp(y, 0.0, 1.0)

    local before = view.zoom
    local step = settings.ZoomStep or 1.18
    local after = clamp((tonumber(data.direction) or 0) > 0 and before * step or before / step, 1.0, settings.ZoomMax or 3.0)

    if after <= 1.0001 then
        view.zoom, view.x, view.y = 1.0, settings.ScreenX or 0.5, settings.ScreenY or 0.45
        return
    end

    if after == before then return end

    -- zoom towards the point under the mouse
    local ratio = after / before
    view.zoom = after
    view.x = clamp(x + (view.x - x) * ratio, -1.0, 2.0)
    view.y = clamp(y + (view.y - y) * ratio, -1.0, 2.0)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then Preview.stop() end
end)

return Preview
