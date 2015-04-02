util.AddNetworkString( "PoliceCallNet" )
util.AddNetworkString( "CallP" )

local function inGroup( gtab, gid )
	for _,g in pairs( gtab ) do
		if _G[g] ~= nil and _G[g] == gid then
			return true
		end
	end
	return false
end

local function countPlayers(g)
	return table.Count(team.GetPlayers(g)) or 0
end

local copson = false

hook.Add( "OnPlayerChangedTeam", "PoliceOfficersQuestionmark", function( ply, oldt, newt )
	local newtAllowed, oldtAllowed = inGroup( PPC.AllowedTeams, newt ), inGroup( PPC.AllowedTeams, oldt )
	if not newtAllowed or not oldtAllowed then return end
	
	if newtAllowed or ( oldtAllowed and countPlayers( oldt ) ~= 0 ) then
		copson = true
	else
		copson = false
	end
end )

hook.Add( "PlayerSay", "911Calls", function( ply, msg )
	local cmd = string.gsub( msg, "%s.*", "" )
	if table.HasValue( PPC.ChatCommands, cmd ) then
		msg = string.sub( msg, cmd:len() + 1 ) -- also removes whitespace bewteen msg and cmd
		if ply.lasttimeused then
			if ply.lasttimeused + PPC.MessageCD > CurTime() then
				local waittime = PPC.MessageCD - math.floor( CurTime() - ply.lasttimeused )
				ply:PrintMessage(HUD_PRINTTALK, "You might want to wait another " .. tostring( waittime ) .. " second(s)")
				return false
			end
		end
		if msg:len() >= PPC.MinMsgLength and msg:len() <= PPC.MaxMsgLength then
			if copson then
				net.Start( "PoliceCallNet" )
					net.WriteString( msg )
					net.WriteEntity( ply )
				net.Send( ply )
				ply:PrintMessage( HUD_PRINTTALK, "You have sent an report to all online officers: " .. msg )
				ply.lasttimeused = CurTime()
				return false
			else
				ply:PrintMessage( HUD_PRINTTALK, "Sorry there are no online officers!" )
				return false
			end
		else
			ply:PrintMessage( HUD_PRINTTALK, "Your message is either way too short, or it was too long to display, write about " .. PPC.MinMsgLength .. "-" .. PPC.MaxMsgLength .. " cars!" )
			return false
		end
	end
end )


net.Receive( "CallP", function(len, ply)
	local plycall = net.ReadEntity()
	local bool = net.ReadBit()
	if bool == 0 then
		ply:Say("/g I will not be able to help the citizen, named: "..plycall:Nick().."!", false)
	elseif bool == 1 then
		ply:Say("/g I am responding to the call of the citizen named: "..plycall:Nick().."!", false)
	end
end )
