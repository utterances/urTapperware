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