# Sinister H-Town RP — Full Commands Reference

## PLAYER COMMANDS (Everyone)

| Command | Purpose | Resource |
|---------|---------|----------|
| /fixme | Emergency teleport to Pink Cage Motel (fixes black screen) | fix_black |
| /clockin | Clock in/out at your job location | sinister_clockin |
| /phone | Open NPWD phone | npwd |
| /mdt | Open Police MDT (LEO/civilian access) | ps-mdt |
| /uofreport | File Use of Force report (LEO only) | ad_incidentreport |
| /buy | Open in-game Tebex store | sinister_store |
| /gang [action] | Gang management commands | qbx_core |
| /gangchat | Gang-only chat | qbx_core |
| /multijob | Manage multiple jobs | multijob_menu |
| /emotes | Open emote menu | sinister_emotes |
| /sit | Toggle dynamic sitting | sinister_sit |
| /engine | Toggle vehicle engine on/off | sinister_engine |
| /chess | Start chess game at table | sinister_chess |
| /marry [ID] | Propose marriage to player | sinister_marry |
| /divorce | File for divorce | sinister_marry |
| /givecash [ID] [amount] | Give cash to player | qbx_core |
| /givekeys [ID] | Give vehicle keys | qbx_vehiclekeys |
| /911 [message] | Send emergency alert to police/EMS | qbx_smallresources |
| /taxi | Call a taxi | qbx_taxijob |
| /tow | Request a tow | qbx_towjob |
| /report [message] | Report a player/bug to admins | easyadmin |
| /me [action] | Describe your character's action | sinonist_chat |
| /do [action] | Describe something in the world | sinonist_chat |
| /ooc [message] | Out-of-character chat | sinonist_chat |
| /twt [message] | Post to Twitter (NPWD) | npwd |
| /anon [message] | Post anonymous tweet | npwd |
| /darkweb [message] | Post to Dark Web | npwd |

## GANG COMMANDS

| Command | Purpose |
|---------|---------|
| /gang create [name] | Create a gang (boss only after admin approval) |
| /gang invite [ID] | Invite player to gang |
| /gang kick [ID] | Remove gang member |
| /gang promote [ID] | Promote member rank |
| /gang demote [ID] | Demote member rank |
| /gang info | View gang stats and bank |
| /gang members | List all gang members |
| /gang deposit [amount] | Deposit money to gang bank |
| /gang withdraw [amount] | Withdraw from gang bank (boss only) |
| /gangchat [msg] | Gang-only chat shortcut |
| /gang disband | Disband gang (boss only) |

## POLICE COMMANDS (HPD / Sheriff / DPS / FIB)

| Command | Purpose | Resource |
|---------|---------|----------|
| /clockin | Go on/off duty | qbx_police |
| /mdt | Open Police Mobile Data Terminal | ps-mdt |
| /uofreport | File Use of Force / Incident Report | ad_incidentreport |
| /cuff [ID] | Handcuff a suspect | qbx_police |
| /uncuff [ID] | Remove handcuffs | qbx_police |
| /jail [ID] [time] | Jail a suspect (minutes) | qbx_police |
| /unjail [ID] | Release from jail | qbx_police |
| /fine [ID] [amount] | Issue a fine | qbx_police |
| /seize | Seize weapons/items from cuffed suspect | qbx_police |
| /911a [message] | Respond to 911 call | qbx_smallresources |
| /clear [ID] | Clear a player's record | qbx_police |
| /es [ID] [grade] | Emergency search a player | qbx_police |
| /spike | Place spike strips | spike_strips |
| /federal [ID] | Flag as federal case (FIB only) | qbx_police |
| /evidence | Open evidence collection menu | evidence_forensic |
| /bodycam | Toggle body camera | qbx_police |
| /dashcam | Toggle dash camera | qbx_smallresources |
| /plate [plate] | Look up license plate | lgd_policeradar |
| /backup | Request backup | qbx_police |
| /dna | Take DNA sample | evidence_forensic |
| /fingerprint | Take fingerprint | evidence_forensic |
| /seizevehicle [plate] | Impound a vehicle | qbx_police |

## EMS / FIRE COMMANDS

| Command | Purpose | Job |
|---------|---------|-----|
| /clockin | Go on/off duty | EMS / Fire |
| /revive [ID] | Revive downed player (EMS only) | ambulance |
| /checkin | Check patient into hospital | ambulance |
| /heal [ID] | Heal player (EMS only) | ambulance |
| /extract | Extract player from vehicle (Fire only) | fire |

## CIVILIAN JOB COMMANDS

| Command | Job | Purpose |
|---------|-----|---------|
| /realtor | Real Estate | Open real estate menu |
| /showhouse [ID] | Real Estate | Show property to buyer |
| /sellproperty [ID] | Real Estate | Sell property to player |
| /taxi | Taxi | Taxi dispatch/accept fare |
| /far [amount] | Taxi | Set fare amount |
| /busroute | Bus | Start bus route |
| /cardealer | Vehicle Dealer | Open dealership menu |
| /testdrive [vehicle] | Vehicle Dealer | Test drive vehicle |
| /repair | Mechanic | Repair vehicle at shop |
| /mod | Mechanic | Open vehicle modification menu |
| /tow | Towing | Tow/dispatch response |
| /impound | Towing | Impound vehicle |
| /truckroute | Trucking | Start trucking route |
| /loadcargo | Trucking/Movers | Load cargo into truck |
| /unload | Movers/Logging | Unload cargo/deliver |
| /garbageroute | Sanitation | Start garbage route |
| /picking | Vineyard | Start picking work |
| /setcart | Hot Dog | Set up cart |
| /sellfood | Hot Dog | Sell food to player |
| /choptree | Logging | Chop tree minigame |
| /joincrew [ID] | Logging | Join logging crew |
| /upgrade | Logging | Upgrade axe skill |
| /drill | Oil Job | Operate drill |
| /pump | Oil Job | Pump oil |
| /wash | Car Wash | Start washing vehicle |
| /startshift | Car Wash | Start work shift |
| /bossmenu | Car Wash/Fuel | Open business boss panel |
| /fuelmenu | Fuel Station | Manage fuel station |
| /buyfuel | Fuel Station | Restock fuel inventory |
| /acceptmove | Movers | Accept moving job |

## CRIMINAL COMMANDS

| Command | Purpose | Resource |
|---------|---------|----------|
| /drugspots | View active drug spot locations | sinister_crime |
| /deal [id] | Sell drugs to AI buyer | sinister_crime |
| /claimspot | Claim unowned drug spot | sinister_crime |
| /craft [recipe] | Craft item at station | sinister_crafting |
| /joinrace [id] | Join street race | sinister_racing |
| /leaverace | Leave active race | sinister_racing |
| /startrace | Start race countdown | sinister_racing |
| /raceleaderboard | View racing leaderboard | sinister_racing |
| /callairdrop | Call flare airdrop | sinister_airdrops |
| /diggrave | Start grave digging | sinister_graverob |
| /hijack | Start truck hijacking mission | sinister_hijacking |
| /chess | Play chess wager match | sinister_chess |
| /darkweb [msg] | Post to Dark Web | npwd |
| /underworld | Open Underworld app (gang stats) | sinister_underworld |

## ADMIN COMMANDS

| Command | Purpose | Resource |
|---------|---------|----------|
| /admin | Open admin menu (GUI) | easyadmin |
| /ban [ID] [reason] | Ban player permanently | easyadmin |
| /tempban [ID] [time] [reason] | Temp ban player | easyadmin |
| /unban [ID] | Unban player | easyadmin |
| /kick [ID] [reason] | Kick player | easyadmin |
| /mute [ID] | Mute player | easyadmin |
| /jail [ID] [time] | Admin jail | easyadmin |
| /tp [ID] | Teleport to player | easyadmin |
| /bring [ID] | Bring player to you | easyadmin |
| /freeze [ID] | Freeze player in place | easyadmin |
| /slap [ID] | Slap player (ragdoll) | easyadmin |
| /ss [ID] | Screenshot player's screen | easyadmin |
| /setmoney [ID] [type] [amount] | Set player money | easyadmin |
| /setjob [ID] [job] [grade] | Set player's job | easyadmin |
| /setgang [ID] [gang] [grade] | Set player's gang | easyadmin |
| /giveitem [ID] [item] [amount] | Give item to player | easyadmin |
| /givevehicle [ID] [model] | Give vehicle to player | easyadmin |
| /revive [ID] | Admin revive | easyadmin |
| /announce [message] | Send server announcement | easyadmin |
| /weather [type] | Change weather | easyadmin |
| /time [hour] [min] | Set server time | easyadmin |
| /clearinv [ID] | Clear player inventory | easyadmin |

## TEBEX STORE

| Command | Purpose |
|---------|---------|
| /buy | Open in-game Tebex store catalog |

## CREATOR COMMANDS (Owner Only)

| Command | Purpose |
|---------|---------|
| /spoody_itemcreator | Open in-game item creator tool |
