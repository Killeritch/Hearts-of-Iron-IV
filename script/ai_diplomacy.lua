require('diplomacy')

function CTargetedAllianceAction_GetAIAcceptanceDerived(action, desc, diplolist)
	local ret = 0
	local actor = action:GetActor()
	local recipient = action:GetRecipient()

	Diplomacy.AddDiploChance(diplolist, ret, CString("TestReason1"), 10)
	Diplomacy.AddDiploChance(diplolist, ret, CString("TestReason2"), -5)

	return ret
end