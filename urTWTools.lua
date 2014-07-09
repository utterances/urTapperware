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

-- return index of object in a table, or 0 if not in table
function tableIndexOf( t, obj )
	for i = 1, #t do
		if t[i] == obj then
			return i
		end
	end
	return 0
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

function deltax(_dx, _dy) return _dx end
function deltay(_dx, _dy) return _dy end



-- ====================
-- = rounding numbers =
-- ====================
-- http://lua-users.org/wiki/FormattingNumbers

function round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

-- =================
-- = slicing array =
-- =================

function pick(t,...)
	local out = {}
	for i =1,select ('#',...) do
		out[#out+1] = t[select (i,...)]
	end
	return out
end 
