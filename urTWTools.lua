-- ========================
-- = Misc Tools & Helpers =
-- ========================

-- table deletion of specific object
function tableRemoveObj( t, obj )
	for i = 1, #t do
		if t[i] == obj then
			table.remove(t, i)
		end
	end
end

-- check if table contains obj
function tableHasObj( t, obj )
	for i = 1, #t do
		if t[i] == obj then
			return true
		end
	end
	return false
end

-- check if table is empty
function tableIsEmpty (self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end


-- =======================================
-- = functional tuple for gesture points =
-- =======================================
-- functional tuple design from http://lua-users.org/wiki/FunctionalTuples
-- each point in gesture table is a dx,dy tuple

function Point(_dx, _dy)
  return function(fn) return fn(_dx, _dy) end
end

function dx(_dx, _dy) return _dx end
function dy(_dx, _dy) return _dy end