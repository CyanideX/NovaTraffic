local ResolutionPresets = {}

function ResolutionPresets.Set(width, height)
    local presets = {
      --{ 1,    2,    3, 4, 5, 6, 7, 8, 9, 10, 11,   12,  13, 14, 15,   16, 17, 18,  19,  20, 21, 22, 23,  24,  25,  26,  27, 28, 29, 30, 31, 32,  33, 34, 35, 36,  37, 38, 39,   40, 41 },
        { 3840, 2160, 8, 6, 5, 5, 6, 7, 1, 1,  0.7,  140, 34, 36, 0.62, 1,  6,  352, 396, 33, 34, 6,  650, 263, 350, 7.5, 9,  8,  5,  34, 34, 30, 140, 36, 36, 215, 10, 1,  3,    65, 350 },
        { 2560, 1440, 8, 6, 1, 3, 6, 7, 1, 1,  0.45, 122, 28, 28, 0.85, 1,  8,  292, 324, 29, 34, 4,  500, 222, 298, 7.5, 8,  8,  3,  32, 32, 18, 130, 34, 36, 185, 10, 1,  3.5,  45, 300 },
        { 1920, 1080, 5, 4, 1, 4, 6, 6, 1, 1,  0.5,  100, 24, 24, 0.85, 1,  0,  237, 258, 21, 30, 4,  400, 169, 232, 4.8, 9,  8,  6,  27, 27, 16, 100, 30, 22, 147, 6,  1,  1.75, 35, 232 },
        { 0,    0,    5, 4, 1, 4, 6, 6, 1, 1,  0.5,  100, 24, 24, 0.85, 1,  0,  237, 258, 21, 30, 4,  400, 169, 232, 4.8, 9,  8,  6,  27, 27, 16, 100, 30, 22, 147, 6,  1,  3.5,  35, 232 },
    }

    for _, preset in ipairs(presets) do
        if width >= preset[1] and height >= preset[2] then
            itemSpacingXValue = preset[3]
            itemSpacingYValue = preset[4]
            framePaddingXValue = preset[5]
            framePaddingYValue = preset[6]
            glyphFramePaddingXValue = preset[7]
            glyphFramePaddingYValue = preset[8]
            glyphItemSpacingXValue = preset[9]
            glyphItemSpacingYValue = preset[10]
            glyphAlignYValue = preset[11]
            buttonWidth = preset[12]
            buttonHeight = preset[13]
            unused = preset[14]
            customFontScale = preset[15]
            defaultFontScale = preset[16]
            dummySpacingYValue = preset[17]
            uiMinWidth = preset[18]
            uiMinHeight = preset[19]
            buttonPaddingRight = preset[20]
            searchPaddingXValue = preset[21]
            searchPaddingYValue = preset[22]
            uiTimeMinWidth = preset[23]
            uiTimeMinHeight = preset[24]
            uiTimeMaxHeight = preset[25]
            uiTimeHourRightPadding = preset[26]
            frameTabPaddingXValue = preset[27]
            frameTabPaddingYValue = preset[28]
            itemTabSpacingYValue = preset[29]
            glyphButtonWidth = preset[30]
            glyphButtonHeight = preset[31]
            timeSliderXPadding = preset[32]
            toggleSpacingXValue = preset[33]
            invisibleButtonWidth = preset[34]
            invisibleButtonHeight = preset[35]
            weatherControlYOffset = preset[36]
            sliderHeight = preset[37]
            exportDebugValue = preset[38]
            exportDebugFrameYMulti = preset[39]
            exportDebugButtonYOffset = preset[40]
            uiCloudCustomizerHeight = preset[41]
            break
        end
    end
end

return ResolutionPresets
