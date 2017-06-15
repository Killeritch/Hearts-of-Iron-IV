local P = {}
Diplomacy = P

function P.AddDiploChance(diplolist, ret, desc, val)
	CArrayDiploChance.Append(diplolist,desc,val)	
	ret = ret + val
end

return Diplomacy