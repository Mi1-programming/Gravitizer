local cursorPoints = {
	Vec(0, 0, 0),
	Vec(1, 0, 0),
	Vec(-1, 0, 0),
	Vec(0, 1, 0),
	Vec(0, -1, 0),
	Vec(0, 0, 1),
	Vec(0, 0, -1),
}
local cursors = {}
local cursorRot = {0, 0, 0}
local cursorSpin = {50, 50, 0}
local maxVerts = 8

function tickCursor(dt)
    --Apply rotation to cursors and draw them
	cursorRot[1] = cursorRot[1] + (cursorSpin[1]*dt)
	cursorRot[2] = cursorRot[2] + (cursorSpin[2]*dt)
	cursorRot[3] = cursorRot[3] + (cursorSpin[3]*dt)
	drawCursors()
end
function drawCursors()
	table.insert(cursors, endRay)
	if #cursors > maxVerts then table.remove(cursors, 1) end

	for i=1, #cursorPoints do
		local prev = endRay
		for i2=1, #cursors do
			local offset = QuatRotateVec(QuatEuler(cursorRot[1], cursorRot[2], cursorRot[3]), VecScale(cursorPoints[i], adjustable.size.val))
			local val = (#cursors-i2+1)
			DrawLine(VecAdd(prev, offset), VecAdd(cursors[val], offset), 1, 1, 1, 1)
			prev = cursors[val]
		end
	end
end
function resetCursors()
	cursors = {}
end