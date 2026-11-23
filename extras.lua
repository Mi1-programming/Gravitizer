--A collection of common functions

function VecLerp(vectorA, vectorB, t)
    return VecAdd(vectorA, VecScale(VecSub(vectorB, vectorA), t))
end
function lerp(valA, valB, t)
	return valA + (valB - valA) * t
end
function randomOffset(vector, offset, decimal)
    local rand = Vec(
    math.random(0, offset*10^decimal)/10^decimal,
    math.random(0, offset*10^decimal)/10^decimal,
    math.random(0, offset*10^decimal)/10^decimal
    )
    return VecAdd(vector, VecSub(rand, VecScale(Vec(offset, offset, offset), 0.5)))
end
function clamp(value, min, max)
	if value > max then
		value = max
	end
	if value < min then
		value = min
	end
	return value
end
function calculateDistance(first, last)
    return math.sqrt((first[1] - last[1])^2 + (first[2] - last[2])^2 + (first[3] - last[3])^2)
end
function boolToNumber(value)
    return value and 1 or 0
end