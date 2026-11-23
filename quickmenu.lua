#include "main.lua"
#include "preview.lua"
#include "extras.lua"

elements = {}

local spacing = 5
local current = 1
isIncreasing = 0
animTime = 1

--Elements
function addNumElementToQuick(newIcon, newVariable, newName, newMin, newMax, newPrecision)
	table.insert(elements, 
	{icon=newIcon, variable=newVariable, name=newName, min=newMin, max=newMax, precision=newPrecision, elementType="number"}
	)
end
function addStateElementToQuick(newIcon, newVariable, newName, newStates)
	table.insert(elements, 
	{icon=newIcon, variable=newVariable, name=newName, states=newStates, elementType="state"}
	)
end

function drawQuickMenu()
	--Color animations
	local colorAnimTime = getColor()
    UiPush()
		UiTranslate(0, UiHeight() - 64)
        UiTranslate(spacing, -spacing)
        for x=1, #elements do
			UiColor(colorAnimTime, colorAnimTime, colorAnimTime, 1)

			--Reverse X
			local rx = #elements-x+1

			if rx == current then
				UiImageBox("menu/panel.png", 64, 64, 5, 5)
				UiImage(elements[rx].icon)

				UiPush()
					UiTranslate(64 + spacing, 32)
					UiFont("bold.ttf", 24)

					--Element type selector
					local newText = "none"
					if elements[rx].elementType == "number" then
						newText = elements[rx].name .. ": " .. tostring(math.floor(adjustable[elements[rx].variable].val * 100) / 100)
					elseif elements[rx].elementType == "state" then
						newText = elements[rx].name .. ": " .. elements[rx].states[adjustable[elements[rx].variable].val]
					end

					local tw, th = UiGetTextSize(newText)
					local sizeX = tw + spacing + 8
					local sizeY = 48

					UiTranslate(-spacing, 0)
					UiScale(lerp(0, 1, animTime))
					UiAlign("left middle")
					UiPush()		
						UiImageBox("menu/panel_leftopen.png", sizeX, sizeY, 5, 5)
					UiPop()
					UiTranslate(spacing, 0)
					UiText(newText)
				UiPop()
			else
				UiColor(0, 0, 0, 1)
				UiImageBox("menu/panel.png", 64, 64, 5, 5)
				UiImage(elements[rx].icon)
			end			
            UiTranslate(0, -64 - spacing)
        end
    UiPop()
end
function tickQuickMenu()
    if InputDown("shift") then
		SetBool("game.player.toolselect", false)
		SetBool("game.input.locktool", true)

		--Element type selector
		local value = 0
		if elements[current].elementType == "number" then
			value = clamp(adjustable[elements[current].variable].val + (InputValue("mousewheel") * (adjustable[elements[current].variable].val * elements[current].precision)), elements[current].min, elements[current].max)
		elseif elements[current].elementType == "state" then
			value = clamp(adjustable[elements[current].variable].val + InputValue("mousewheel"), 1, #elements[current].states)
		end

		if value ~= adjustable[elements[current].variable].val then
			showPreview()
			adjustable[elements[current].variable].val = value

			--Scroll sound
			isIncreasing = 1
			SetValue("isIncreasing", 0, "linear", 0.25)
		end	
		if isIncreasing > 0 then
			UiSoundLoop("MOD/snd/quickmenuValue.ogg", isIncreasing * 0.5)
		end

        local value = InputLastPressedKey()
	    value = tonumber(value)
	    if value ~= nill then
			if value <= #elements and value > 0 and value ~= current then
            	current = value
				UiSound("MOD/snd/quickmenuSwap.ogg", 0.75)

				animTime = 0
				SetValue("animTime", 1, "easeout", 0.25)
			end
	    end
	else
		SetBool("game.input.locktool", false)
	end
end
function getColor()
	--Color animations
	local colorAnimTime = ((math.sin(GetTime() * 2) + 1) / 2) / 4 + 0.75
	return colorAnimTime
end