#include "cursors.lua"
#include "extras.lua"
#include "preview.lua"
#include "quickmenu.lua"

function init()
	--Variables
	adjustable = {
		size = {
			val = 2,
		},
		power = {
			val = 3,
		},
		applyon = {
			val = 1,
		},
		gravitymode = {
			val = 1,
		},
	}

	--Add adjustable values to quick menu
	addNumElementToQuick("menu/icons/size.png", "size", "Size", 0.25, 10000, 0.125)
	addNumElementToQuick("menu/icons/power.png", "power", "Power", 0.1, 10000, 0.05)
	addStateElementToQuick("menu/icons/applyon.png", "applyon", "Apply On", {"Release", "Select"})
	addStateElementToQuick("menu/icons/gravitymode.png", "gravitymode", "Gravity Mode", {"Gravity", "Wind"})

	baseGravity = Vec(0, -10, 0) --(NOTE: Teardown's base gravity seems to be 10m/s2)
	smoothness = 0.5
	range = 100 
	lastPos = Vec(0, 0, 0)
	velocity = Vec(0, 0, 0)
	selections = {}

	--Tool
	toolT = Transform()
	toolTip = Vec(0.425, -0.175, -1.1)
	particles = true

	--Animation related variables
	shake = 0
	shakePower = 0
	pillarTime = 0
	glassTime = 0
	onAmount = 1
	offAmount = 0
	speed = offAmount
	
    --Register tool and enable it
	RegisterTool("gravitizer", "Gravitizer", "MOD/vox/model.vox", 6)
	SetBool("game.tool.gravitizer.enabled", true)
	SetString("game.tool.gravitizer.ammo.display", "")

	--Sounds
	select = LoadSound("MOD/snd/select.ogg")
	deselect = LoadSound("MOD/snd/deselect.ogg")
	startbeam = LoadSound("MOD/snd/startbeam.ogg")
	beam = LoadLoop("MOD/snd/beam.ogg")
end
function tick(dt)
	if GetString("game.player.tool") ~= "gravitizer" then resetAnim(); return end

	--Reset tool position
	SetToolTransform(Transform(toolT.pos, toolT.rot))

	if shake > 0 then
		--Shake
		SetToolTransform(Transform(randomOffset(toolT.pos, shakePower*shake, 3), toolT.rot))
	end

	tickQuickMenu(dt)

	if not GetBool("game.player.canusetool") then return end

	--Get camera variables
	local camT = GetCameraTransform()
	local endPoint = TransformToParentVec(camT, Vec(0, 0, -1))

	--If clicked shoot new raycast
	if InputPressed("usetool") then
		_, dist = QueryRaycast(camT.pos, endPoint, range, 0, false)
		lastPos = VecAdd(TransformToParentVec(camT, Vec(0, 0, -dist)), camT.pos)

		resetCursors()

		PlaySound(startbeam, camT.pos, 0.575)

		--Set speeds
		SetValue("speed", onAmount, "easeout", 0.5)
	end

	--Remove selections
	if InputPressed("grab") and not InputDown("usetool") then
		if GetPlayerGrabBody() == 0 then
			if #selections > 0 then
				PlaySound(deselect, camT.pos, 0.55)
				shake = 1
				SetValue("shake", 0, "linear", 0.25)
				shakePower = 0.035
			end
			selections = {}
		end
	end
	
	shake = 0

	--If left click held down move shot raycast
	if InputDown("usetool") then

		--Calculate ray end position
		endRay = VecAdd(TransformToParentVec(camT, Vec(0, 0, -dist)), camT.pos)

		shake = 1
		shakePower = 0.01

		--Get velocity
		velocity = VecLerp(velocity, VecSub(endRay, lastPos), 1 - smoothness)
		lastPos = VecCopy(endRay)

		--Draw ray
		local toolT = GetBodyTransform(GetToolBody())
		DrawLine(VecAdd(toolT.pos, TransformToParentVec(toolT, toolTip)), endRay, 1, 1, 1, 1)

		--Get objects in selector
		QueryRequire("physical dynamic")
		local bodies = QueryAabbBodies(VecSub(endRay, 
		Vec(adjustable.size.val, adjustable.size.val, adjustable.size.val)), 
		VecAdd(endRay, Vec(adjustable.size.val, adjustable.size.val, adjustable.size.val)))
		local newSels = false
		for x=1, #bodies do
			local exists = false
			for x2=1, #selections do
				--If already selected
				if selections[x2]["handle"] == bodies[x] then
					exists = true

					selections[x2]["gravity"] = VecScale(velocity, (1/dt)/100*adjustable.power.val)
					selections[x2]["active"] = false
					selections[x2]["gravitytype"] = adjustable.gravitymode.val
					break
				end
			end				
			if IsBodyDynamic(bodies[x]) and not exists then
				--Create selection
				local selection = {}
				selection["handle"] = bodies[x]
				selection["gravity"] = VecScale(velocity, (1/dt)/100*adjustable.power.val)
				selections["active"] = false
				selections["gravitytype"] = adjustable.gravitymode.val
				table.insert(selections, selection)	
				newSels = true
			end
		end
		if newSels then PlaySound(select, camT.pos, 0.7) end
		PlayLoop(beam, camT.pos, 0.7)

		--Particles
		if particles then
			beamStartParticles(toolT, camT)
			beamBaseParticles(VecAdd(TransformToParentVec(toolT, toolTip), toolT.pos), lastPos, camT)
			beamEndParticles(endRay, VecScale(velocity, 20))
		end

		--Lighting
		PointLight(VecAdd(TransformToParentVec(camT, Vec(0, 0, -1)), camT.pos), 0.25, 0.25, 0.25, 0.1)
	else
		_, dist = QueryRaycast(camT.pos, endPoint, range, 0, false)
		lastPos = VecAdd(TransformToParentVec(camT, Vec(0, 0, -dist)), camT.pos)
	end

	if InputReleased("usetool") then
		for x=1, #selections do
			selections[x]["active"] = true
		end
		velocity = Vec(0, 0, 0)

		--Set glass rotation speed
		SetValue("speed", offAmount, "easeout", 1)
	end

	--Drawing
	drawPreview(lastPos, adjustable.size.val)
	drawSelections()
	tickCursor(dt)

	--Animation

	--Rotate the glass display part of the tool and move the pillars
	local b = GetToolBody()
	local glassOrigin = Transform(Vec(0.425, -0.175, -0.825))
	glassTime = glassTime + lerp(100, 133 * adjustable.size.val * adjustable.power.val, speed)*dt
	pillarTime = pillarTime + lerp(5, 25, speed)*dt
	if body ~= b then
		body = b

		glassObj = GetBodyShapes(b)[2]
		pillar1 = GetBodyShapes(b)[3]
		pillar2 = GetBodyShapes(b)[4]
		pillar3 = GetBodyShapes(b)[5]

		glassTransform = TransformToLocalTransform(glassOrigin, GetShapeLocalTransform(glassObj))	
	end
	glassOrigin.rot = QuatEuler(0, glassTime, 0)

	local newGlassT = TransformToParentTransform(glassOrigin, glassTransform)
	SetShapeLocalTransform(glassObj, newGlassT)
	
	SetShapeLocalTransform(pillar1, Transform(Vec(0.4, -0.15 + ((math.sin(pillarTime)/2)-0.5)*0.025, -0.5), QuatEuler(-90, 0, 0)))
	SetShapeLocalTransform(pillar2, Transform(Vec(0.4, -0.125 + ((math.sin(pillarTime*3)/2)-0.5)*0.025, -0.4), QuatEuler(-90, 0, 0)))
	SetShapeLocalTransform(pillar3, Transform(Vec(0.4, -0.1 + ((math.sin(pillarTime*6)/2)-0.5)*0.025, -0.3), QuatEuler(-90, 0, 0)))
end
function resetAnim()
	shake = 0
	speed = offAmount
	glassTime = 0
	pillarTime = 0
end
function update(dt)
	for k, v in ipairs(selections) do
		if IsBodyDynamic(v.handle) then
				local oppositeForce = Vec(0, 0, 0)
			if v["gravitytype"] == 1 then oppositeForce = VecCopy(baseGravity) end

			if v["active"] or adjustable.applyon.val == 2 then
				--Apply gravity in the opposite direction and then in the selection direction
				SetBodyVelocity(v["handle"], VecAdd(GetBodyVelocity(v["handle"]), VecAdd(VecScale(oppositeForce, -dt), v["gravity"])))
			else
				--Apply gravity in the opposite direction
				SetBodyVelocity(v["handle"], VecScale(oppositeForce, -dt))
			end
		else
			table.remove(selections, k)
		end
	end
end
function draw()
	if GetString("game.player.tool") ~= "gravitizer" then return end
	drawQuickMenu()
end
function drawSelections()
	for x=1, #selections do
		--Calculate colors
		local g = selections[x]["gravity"]
		local col = Vec(0.5, 0.5, 0.5)
		if VecLength(g) > 0.01 then
			col = VecScale(VecAdd(VecNormalize(g), Vec(1, 1, 1)), 0.5)
		end
		--Draw outline
		DrawBodyOutline(selections[x]["handle"], col[1], col[2], col[3], 0.75)
	end
end
--PARTICLES
function beamStartParticles(toolT, camT)
	ParticleType("plain")
	ParticleTile(4)
	ParticleColor(1, 1, 1, 1, 1, 1)
	ParticleEmissive(6)
	ParticleRadius(0.1, 0.01, "easeout")
	SpawnParticle(VecAdd(TransformToParentVec(toolT, toolTip), toolT.pos), randomOffset(TransformToParentVec(camT, Vec(0, 0, -7)), 2, 3), 0.2)
end
function beamBaseParticles(first, last, camT)
	local steps = calculateDistance(first, last) * 5 -- <-- Number of particles per meter
	for x=1, steps do
		ParticleType("plain")
		ParticleTile(0)
		ParticleColor(1, 1, 1, 1, 1, 1)
		ParticleEmissive(0.1, 0, "smooth")
		ParticleRadius(lerp(clamp(adjustable.size.val/30, 0.05, 0.35), 0, x/steps), 0)
		ParticleCollide(0)
		SpawnParticle(VecLerp(first, last, x/steps), randomOffset(TransformToParentVec(camT, Vec(0, 0, -4)), 1, 2), 0.1)
	end
end
function beamEndParticles(origin, velocity)
	ParticleType("plain")
	ParticleTile(4)
	ParticleColor(1, 1, 1, 1, 1, 1)
	ParticleEmissive(0.075 * VecLength(velocity) + 0.025, 0, "linear")
	ParticleRadius(0, 0.1, "smooth")
	SpawnParticle(randomOffset(origin, adjustable.size.val*2, 3), velocity, 0.35)
end