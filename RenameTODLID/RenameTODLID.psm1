
function GetMainMenuItems()
{
    param($getMainMenuItemsArgs)

    $menuItem = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem.Description = "Rename DLgame to ID"
    $menuItem.FunctionName = "RenameGameNameToDLID"
    return $menuItem
}

function RenameGameNameToDLID() {
    param(
        $scriptMainMenuItemActionArgs
    )

    $success = 0
    $fail = 0
	
    ## go to thought each game in selection
    foreach ($game in $PlayniteApi.MainView.SelectedGames) {
        #Get Data
        ## full path of file
        $path = $game.InstallDirectory
        ## name of game
        $name = $game.Name
        $fixname = GetName $path $name
        $GameIDresult = GetGameID $fixname.RJID $fixname.pathname $fixname.autoname 
        $GameID = $GameIDresult.id
        $GameIDway = $GameIDresult.way
        $GameIDkeyword = $GameIDresult.keyword
        #check if game is RJ[8]||VJ[8]
        if ($GameID -match "(RJ\d{8})") {
            $game.Name = $GameID
            $game.SortingName = "$GameID = $GameIDway = $GameIDkeyword"
            $success++
        }
        elseif($GameID -match "(VJ\d{8})") {
            $game.Name = "https://www.dlsite.com/pro/work/=/product_id/$GameID.html"
            $game.SortingName = "$GameID = $GameIDway = $GameIDkeyword"
            $success++
        }
        #check if game is RJ[6]||VJ[6]
        elseif ($GameID -match "(RJ\d{6})") {
            $game.Name = $GameID
            $game.SortingName = "$GameID = $GameIDway = $GameIDkeyword"
            $success++
        }

        elseif($GameID -match "(VJ\d{6})") {
            $game.Name = "https://www.dlsite.com/pro/work/=/product_id/$GameID.html"
            $game.SortingName = "$GameID = $GameIDway = $GameIDkeyword"
            $success++
        }
        else {
            $game.SortingName = "$GameID = $GameIDway = $GameIDkeyword"
            $fail++
        }
    }

    

    if ($fail -eq 0) {
        $PlayniteApi.Dialogs.ShowMessage("$success games renamed.", "Success", 0, 64)
    }
    else {
        $PlayniteApi.Dialogs.ShowMessage("$success games renamed and $fail failures!", "Warning", 0, 48)
    }

}

function GetName($path1, $name1) {
    $fixname = "" | Select-Object -Property RJID, pathname, autoname
    [string]$testpath = $path
    #check if RJ ID exsit in the path
    if ($testpath -match "(RJ\d{8})" -eq 1) {
        $fixname.RJID = $Matches[0]
    }
    elseif ($testpath -match "(VJ\d{8})" -eq 1) {
        $fixname.RJID = $Matches[0]
    }
    elseif ($testpath -match "(RJ\d{6})" -eq 1) {
        $fixname.RJID = $Matches[0]
    }
    elseif ($testpath -match "(VJ\d{6})" -eq 1) {
        $fixname.RJID = $Matches[0]
    }
    #Try get name from path by the folder name length
    $patharray = $path -split "\\"
    $lastlengthword = ""
    foreach ($i in $patharray) {
        if ($i.length -gt $lastlengthword.length) {
            $lastlengthword = $i
        }
    }
    $dofixname1 = fixnamecha($lastlengthword)
    $fixname.pathname = $dofixname1
    #get and fix auto name field
    $dofixname2 = fixnamecha($name1)
    $fixname.autoname = $dofixname2
    return $fixname
}

function fixnamecha($inputdata){
    $nametofix = $inputdata
    #fixname remove ()
    $nametofix = $nametofix -replace '\(.*?\)', ''
    #fixname remove odd ()
    $nametofix = $nametofix -replace '（.*?）', ''
    #fixname remove []
    $nametofix = $nametofix -replace '\[.*?\]', ''
    #fixname remove 製品版
    $nametofix = $nametofix -replace '製品版', ''
    #fixname remove DL版
    $nametofix = $nametofix -replace 'DL版', ''
    #fixname remove ver+number
    $nametofix = $nametofix -replace '_*~*ver\d.*\d', ''
    #fixname remove v+number
    $nametofix = $nametofix -replace '_*~*v\d.*\d', ''
    $end = $nametofix
    return $end
}

function GetGameID($passRJID, $passpathname, $passautoname) {
    $sentback = ""| Select-Object -Property id,way,keyword
    #debug use
    #$PlayniteApi.Dialogs.ShowMessage("$passRJID", "passRJID")
    #$PlayniteApi.Dialogs.ShowMessage("$passpathname", "passpathname")
    #$PlayniteApi.Dialogs.ShowMessage("$passautoname", "passautoname")

    #if RJ id present then give it back
    if ($passRJID -match "(RJ\d{8})") {
        $sentback.id = $passRJID
        $sentback.way = "RJ text"
        $sentback.keyword = $passRJID
        return $sentback
    }
    #if VJ id present then give it back
    if ($passRJID -match "(VJ\d{8})") {
        $sentback.id = $passRJID
        $sentback.way = "VJ text"
        $sentback.keyword = $passRJID
        return $sentback
    }
    if ($passRJID -match "(RJ\d{6})") {
        $sentback.id = $passRJID
        $sentback.way = "RJ text"
        $sentback.keyword = $passRJID
        return $sentback
    }
    if ($passRJID -match "(VJ\d{6})") {
        $sentback.id = $passRJID
        $sentback.way = "VJ text"
        $sentback.keyword = $passRJID
        return $sentback
    }
    #if not go search DLsite with pathname
    $searchsite1 = "https://www.dlsite.com/maniax/fsr/=/language/jp/sex_category%5B0%5D/male/keyword/" + $passpathname
    try{
    $web1 = Invoke-WebRequest -Uri $searchsite1 -DisableKeepAlive -TimeoutSec 10 -UseBasicParsing -ErrorAction Ignore
    }
    catch{
    }
    if ($web1.StatusCode -eq 200) {
        [string]$result1 = $web1.Links | Where-Object href -match "product_id" | Select-Object -expand href
        if ($result1 -match "RJ\d{8}" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname RJ"
            $sentback.keyword = $passpathname
            return $sentback
        }
        elseif ($result1 -match "VJ\d{8}" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname VJ"
            $sentback.keyword = $passpathname
            return $sentback
        }
	elseif ($result2 -match "(RJ\d{6})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname RJ"
            $sentback.keyword = $passautoname
            return $sentback
        }
        elseif ($result2 -match "(VJ\d{6})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname VJ"
            $sentback.keyword = $passautoname
            return $sentback
        }
    }
    #pathname search done
    #if not go search DLsite with autoname
    $searchsite2 = "https://www.dlsite.com/maniax/fsr/=/language/jp/sex_category%5B0%5D/male/keyword/" + $passautoname
    try{
        $web2 = Invoke-WebRequest -Uri $searchsite2 -DisableKeepAlive -TimeoutSec 10 -UseBasicParsing -ErrorAction Ignore
        }
        catch{
        }
    if ($web2.StatusCode -eq 200) {
        [string]$result2 = $web2.Links | Where-Object href -match "product_id" | Select-Object -expand href
        if ($result2 -match "(RJ\d{8})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname RJ"
            $sentback.keyword = $passautoname
            return $sentback
        }
        elseif ($result2 -match "(VJ\d{8})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname VJ"
            $sentback.keyword = $passautoname
            return $sentback
        }
        elseif ($result3 -match "(RJ\d{6})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname RJ"
            $sentback.keyword = $passpathname
            return $sentback
        }
        elseif ($result3 -match "(VJ\d{6})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname VJ"
            $sentback.keyword = $passautoname
            return $sentback
        }
    }
    #autoname search done
    #if not go search google with pathname
    $searchsite3 = "https://www.google.com/search?q=" + $passpathname + "+sitewww.%3Adlsite.com"
    try{
        $web3 = Invoke-WebRequest -Uri $searchsite3 -DisableKeepAlive -TimeoutSec 10 -UseBasicParsing -ErrorAction Ignore
        }
        catch{
        }
    if ($web3.StatusCode -eq 200) {
        [string]$result3 = $web3.Links | Where-Object href -match "product_id" | Select-Object -expand href
        if ($result3 -match "(RJ\d{8})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname RJ"
            $sentback.keyword = $passpathname
            return $sentback
        }
        elseif ($result3 -match "(VJ\d{8})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname VJ"
            $sentback.keyword = $passautoname
            return $sentback
        }
        elseif ($result3 -match "(RJ\d{6})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname RJ"
            $sentback.keyword = $passpathname
            return $sentback
        }
        elseif ($result3 -match "(VJ\d{6})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname VJ"
            $sentback.keyword = $passautoname
            return $sentback
        }
    }
    #pathname search done
    #if not go search google with autoname
    $searchsite4 = "https://www.google.com/search?q=" + $passautoname + "+sitewww.%3Adlsite.com"
    try{
        $web4 = Invoke-WebRequest -Uri $searchsite4 -DisableKeepAlive -TimeoutSec 10 -UseBasicParsing -ErrorAction Ignore
        }
        catch{
        }
    if ($web4.StatusCode -eq 200) {
        [string]$result4 = $web4.Links | Where-Object href -match "product_id" | Select-Object -expand href
        if ($result4 -match "(RJ\d{8})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname RJ"
            $sentback.keyword = $passpathname
            return $sentback
        }
        elseif ($result4 -match "(VJ\d{8})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname VJ"
            $sentback.keyword = $passautoname
            return $sentback
        }
        elseif ($result4 -match "(RJ\d{6})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname RJ"
            $sentback.keyword = $passpathname
            return $sentback
        }
        elseif ($result4 -match "(VJ\d{6})" -eq 1) {
            $sentback.id = $Matches[0]
            $sentback.way = "DLsite pathname VJ"
            $sentback.keyword = $passautoname
            return $sentback
        }
    }
    #autoname search done
    #no result, sent back debug data
    $sentback.id = ""
    $sentback.way = "none"
    $sentback.keyword = "fail"
    return $sentback
}
