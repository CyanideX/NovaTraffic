local ResolutionPresets = {}

function ResolutionPresets.Set(width, height)
    local presets = {
        buttonHeight = { 34, 28, 24, 24 },
        buttonPaddingRight = { 33, 29, 21, 21 },
        buttonRadius = { 8, 7, 5, 5 },
        buttonWidth = { 140, 122, 100, 100 },
        customFontScale = { 0.62, 0.85, 0.85, 0.85 },
        defaultFontScale = { 1, 1, 1, 1 },
        dummySpacingYValue = { 6, 8, 0, 0 },
        exportDebugButtonYOffset = { 65, 45, 35, 35 },
        exportDebugFrameYMulti = { 3, 3.5, 1.75, 3.5 },
        exportDebugValue = { 1, 1, 1, 1 },
        framePaddingXValue = { 5, 1, 1, 1 },
        framePaddingYValue = { 5, 3, 4, 4 },
        frameTabPaddingXValue = { 9, 8, 9, 9 },
        frameTabPaddingYValue = { 8, 8, 8, 8 },
        glyphAlignYValue = { 0.7, 0.45, 0.5, 0.5 },
        glyphButtonHeight = { 34, 32, 27, 27 },
        glyphButtonWidth = { 34, 32, 27, 27 },
        glyphFramePaddingXValue = { 6, 6, 6, 6 },
        glyphFramePaddingYValue = { 7, 7, 6, 6 },
        glyphItemSpacingXValue = { 1, 1, 1, 1 },
        glyphItemSpacingYValue = { 1, 1, 1, 1 },
        invisibleButtonHeight = { 36, 36, 22, 22 },
        invisibleButtonWidth = { 36, 34, 30, 30 },
        itemSpacingXValue = { 8, 8, 5, 5 },
        itemSpacingYValue = { 6, 6, 4, 4 },
        itemTabSpacingYValue = { 5, 3, 6, 6 },
        searchPaddingXValue = { 34, 34, 30, 30 },
        searchPaddingYValue = { 6, 4, 4, 4 },
        sliderHeight = { 10, 10, 6, 6 },
        timeSliderXPadding = { 30, 18, 16, 16 },
        toggleSpacingXValue = { 140, 130, 100, 100 },
        uiCloudCustomizerHeight = { 350, 300, 232, 232 },
        uiMinHeight = { 396, 324, 258, 258 },
        uiMinWidth = { 352, 292, 237, 237 },
        uiTimeHourRightPadding = { 7.5, 7.5, 4.8, 4.8 },
        uiTimeMaxHeight = { 350, 298, 232, 232 },
        uiTimeMinHeight = { 263, 222, 169, 169 },
        uiTimeMinWidth = { 650, 500, 400, 400 },
        weatherControlYOffset = { 215, 185, 147, 147 }
    }

    local function getPresetValue(presetTable)
        if width >= 3840 then
            return presetTable[1]
        elseif width >= 2560 then
            return presetTable[2]
        elseif width >= 1920 then
            return presetTable[3]
        else
            return presetTable[4]
        end
    end

    buttonHeight = getPresetValue(presets.buttonHeight)
    buttonPaddingRight = getPresetValue(presets.buttonPaddingRight)
    buttonRadius = getPresetValue(presets.buttonRadius)
    buttonWidth = getPresetValue(presets.buttonWidth)
    customFontScale = getPresetValue(presets.customFontScale)
    defaultFontScale = getPresetValue(presets.defaultFontScale)
    dummySpacingYValue = getPresetValue(presets.dummySpacingYValue)
    exportDebugButtonYOffset = getPresetValue(presets.exportDebugButtonYOffset)
    exportDebugFrameYMulti = getPresetValue(presets.exportDebugFrameYMulti)
    exportDebugValue = getPresetValue(presets.exportDebugValue)
    framePaddingXValue = getPresetValue(presets.framePaddingXValue)
    framePaddingYValue = getPresetValue(presets.framePaddingYValue)
    frameTabPaddingXValue = getPresetValue(presets.frameTabPaddingXValue)
    frameTabPaddingYValue = getPresetValue(presets.frameTabPaddingYValue)
    glyphAlignYValue = getPresetValue(presets.glyphAlignYValue)
    glyphButtonHeight = getPresetValue(presets.glyphButtonHeight)
    glyphButtonWidth = getPresetValue(presets.glyphButtonWidth)
    glyphFramePaddingXValue = getPresetValue(presets.glyphFramePaddingXValue)
    glyphFramePaddingYValue = getPresetValue(presets.glyphFramePaddingYValue)
    glyphItemSpacingXValue = getPresetValue(presets.glyphItemSpacingXValue)
    glyphItemSpacingYValue = getPresetValue(presets.glyphItemSpacingYValue)
    invisibleButtonHeight = getPresetValue(presets.invisibleButtonHeight)
    invisibleButtonWidth = getPresetValue(presets.invisibleButtonWidth)
    itemSpacingXValue = getPresetValue(presets.itemSpacingXValue)
    itemSpacingYValue = getPresetValue(presets.itemSpacingYValue)
    itemTabSpacingYValue = getPresetValue(presets.itemTabSpacingYValue)
    searchPaddingXValue = getPresetValue(presets.searchPaddingXValue)
    searchPaddingYValue = getPresetValue(presets.searchPaddingYValue)
    sliderHeight = getPresetValue(presets.sliderHeight)
    timeSliderXPadding = getPresetValue(presets.timeSliderXPadding)
    toggleSpacingXValue = getPresetValue(presets.toggleSpacingXValue)
    uiCloudCustomizerHeight = getPresetValue(presets.uiCloudCustomizerHeight)
    uiMinHeight = getPresetValue(presets.uiMinHeight)
    uiMinWidth = getPresetValue(presets.uiMinWidth)
    uiTimeHourRightPadding = getPresetValue(presets.uiTimeHourRightPadding)
    uiTimeMaxHeight = getPresetValue(presets.uiTimeMaxHeight)
    uiTimeMinHeight = getPresetValue(presets.uiTimeMinHeight)
    uiTimeMinWidth = getPresetValue(presets.uiTimeMinWidth)
    weatherControlYOffset = getPresetValue(presets.weatherControlYOffset)
end

return ResolutionPresets
