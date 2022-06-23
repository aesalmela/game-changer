param
(
	[string]$type
)

#Team Variables
$teamID = "get_team_guid_from_fiddler"
$token = "get_gctoken_from_fiddler"

#Global Variables
$baseURL = "https://api.team-manager.gc.com/teams/$teamID"
$headers = @{ 'gc-token' = $token }
$gamesUrl = "$baseURL/schedule/?fetch_place_details=true"

$response = Invoke-RestMethod -Method Get -Uri $gamesUrl -Headers $headers -ContentType "application/json"
foreach ($e in $response){
    $id = $e.event.id
    $status = $e.event.status
    $fullDay = $e.event.full_day
    $timezone = $e.event.timezone
    $startTime = $e.event.start.datetime
    $endTime = $e.event.end.datetime
    $homeAway = $e.pregame_data.home_away
    $opponentID = $e.pregame_data.opponent_id
    $opponentName = $e.pregame_data.opponent_name
    $lineupID = $e.pregame_data.lineup_id

    Write-Host "Updating $id  $opponentName" 

    #Minimum Patch Update Changes
    $updates = @{}
    $startData = @{"datetime"=$startTime;}
    $endData = @{"datetime"=$endTime;}
    $eventData = @{"status"=$status;"full_day"=$fullDay;"timezone"=$timezone;"start"=$startData;"end"=$endData;"arrive"=$startData;}

    if ($type -eq "game"){
        #Make game
        $subTypeData = @()
    }
    else {
        #Make scrimmage
        $subTypeData = @("scrimmages")
    }

    $eventData.Add("sub_type",$subTypeData)
    $updates.Add("event",$eventData)

    $pregameData = @{"home_away"=$homeAway;"opponent_id"=$opponentID;"opponent_name"=$opponentName;"lineup_id"=$lineupID;}
    $updates.Add("pregame_data",$pregameData)

    $jsonBase = @{}
    $jsonBase.Add("updates",$updates)

    $notificationData = @{"should_notify"=$false;"message"=$null;}
    $jsonBase.Add("notification",$notificationData)

    $payloadJson = $jsonBase | ConvertTo-Json -Depth 10
    $url = "$baseURL/schedule/events/$id"
    $response = Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -ContentType "application/json" -Body $payloadJson
}