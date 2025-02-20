-- WindowUtils.lua
local WindowUtils = {}

-- Hardcoded settings
local gridSize = 20

local animatingWindows = {}
local draggingWindows = {}

local function initializeWindowAnimation(windowName)
    animatingWindows[windowName] = {
        animating = false,
        animationStartTime = 0,
        startPosX = 0,
        startPosY = 0,
        startSizeX = 0,
        startSizeY = 0,
        targetPosX = 0,
        targetPosY = 0,
        targetSizeX = 0,
        targetSizeY = 0
    }
    draggingWindows[windowName] = false
end

local function getWindowAnimationState(windowName)
    if not animatingWindows[windowName] then
        initializeWindowAnimation(windowName)
    end
    return animatingWindows[windowName]
end

function WindowUtils.SnapToGrid(position)
    return math.floor(position / gridSize + 0.5) * gridSize
end

function WindowUtils.EaseInOut(t)
    return t * t * (3 - 2 * t)
end

function WindowUtils.Lerp(a, b, t)
    return a + (b - a) * t
end

function WindowUtils.HandleSnap(currentPosX, currentPosY, currentSizeX, currentSizeY, windowName)
    local animationState = getWindowAnimationState(windowName)
    
    animationState.animating = false
    animationState.startPosX, animationState.startPosY = currentPosX, currentPosY
    animationState.startSizeX, animationState.startSizeY = currentSizeX, currentSizeY
    animationState.targetPosX = WindowUtils.SnapToGrid(currentPosX)
    animationState.targetPosY = WindowUtils.SnapToGrid(currentPosY)
    animationState.targetSizeX = WindowUtils.SnapToGrid(currentSizeX)
    animationState.targetSizeY = WindowUtils.SnapToGrid(currentSizeY)

    ImGui.SetWindowPos(windowName, animationState.targetPosX, animationState.targetPosY)
    ImGui.SetWindowSize(windowName, animationState.targetSizeX, animationState.targetSizeY)
end

function WindowUtils.Animate(windowName, animationTime)
    local animationState = getWindowAnimationState(windowName)
    
    local elapsedTime = os.clock() - animationState.animationStartTime
    local t = math.min(elapsedTime / animationTime, 1)
    t = WindowUtils.EaseInOut(t)

    local newPosX = WindowUtils.Lerp(animationState.startPosX, animationState.targetPosX, t)
    local newPosY = WindowUtils.Lerp(animationState.startPosY, animationState.targetPosY, t)
    local newSizeX = WindowUtils.Lerp(animationState.startSizeX, animationState.targetSizeX, t)
    local newSizeY = WindowUtils.Lerp(animationState.startSizeY, animationState.targetSizeY, t)

    ImGui.SetWindowPos(windowName, newPosX, newPosY)
    ImGui.SetWindowSize(windowName, newSizeX, newSizeY)

    if t >= 1 then
        animationState.animating = false
    end
end

function WindowUtils.UpdateWindow(windowName, gridEnabled, animationEnabled, animationTime)
    local currentPosX, currentPosY = ImGui.GetWindowPos()
    local currentSizeX, currentSizeY = ImGui.GetWindowSize()

    if gridEnabled then
        local isFocused = ImGui.IsWindowFocused()
        local isDragging = ImGui.IsMouseDragging(ImGuiMouseButton.Left)
        local isReleased = ImGui.IsMouseReleased(ImGuiMouseButton.Left)

        if isFocused and isDragging then
            draggingWindows[windowName] = true
        elseif draggingWindows[windowName] and isReleased then
            draggingWindows[windowName] = false
            WindowUtils.HandleSnap(currentPosX, currentPosY, currentSizeX, currentSizeY, windowName)
            if animationEnabled then
                local animationState = getWindowAnimationState(windowName)
                animationState.animating = true
                animationState.animationStartTime = os.clock()
            end
        end
    end

    if animationEnabled then
        local animationState = getWindowAnimationState(windowName)
        if animationState.animating then
            WindowUtils.Animate(windowName, animationTime)
        end
    end
end

return WindowUtils
