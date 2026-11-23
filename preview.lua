--Cube out of lines
local lines = {
	{from=Vec(1, 1, 1), to=Vec(1, -1, 1)},
    {from=Vec(-1, 1, 1), to=Vec(-1, -1, 1)},
    {from=Vec(-1, 1, -1), to=Vec(-1, -1, -1)},
    {from=Vec(1, 1, -1), to=Vec(1, -1, -1)},

    {from=Vec(1, -1, 1), to=Vec(-1, -1, 1)},
    {from=Vec(-1, -1, -1), to=Vec(1, -1, -1)},
    {from=Vec(-1, 1, -1), to=Vec(1, 1, -1)},
    {from=Vec(1, 1, 1), to=Vec(-1, 1, 1)},

    {from=Vec(1, -1, 1), to=Vec(1, -1, -1)},
    {from=Vec(1, 1, 1), to=Vec(1, 1, -1)},
    {from=Vec(-1, -1, 1), to=Vec(-1, -1, -1)},
    {from=Vec(-1, 1, 1), to=Vec(-1, 1, -1)},
}
visibility = 0
local fadeTime = 1

function drawPreview(point, size)
    if visibility == 0 then return end
    for x=1, #lines do
        DrawLine(VecAdd(VecScale(lines[x].from, size), point), VecAdd(VecScale(lines[x].to, size), point), 1, 1, 1, visibility)
    end
end
function showPreview()
    visibility = 1
    SetValue("visibility", 0, "linear", fadeTime)
end