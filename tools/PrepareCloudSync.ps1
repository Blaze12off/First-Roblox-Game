param(
    [long]$PlaceId = 108052777594261,
    [long]$UniverseId = 10770928979,
    [string]$OutputPath = (Join-Path $PSScriptRoot 'CloudSync.tmp')
)
$ErrorActionPreference='Stop'
if($PlaceId -le 0 -or $UniverseId -le 0){throw 'Specify the existing cloud place and universe IDs.'}
$projectRoot=Split-Path $PSScriptRoot -Parent
function Quote-Luau([string]$text){
    $level=1
    while($text.Contains((']'+('='*$level)+']'))){$level++}
    # Lua skips the first newline after the opening long bracket.
    return '['+('='*$level)+"[`n"+$text+']'+('='*$level)+']'
}
$lines=New-Object System.Collections.Generic.List[string]
$lines.Add('-- Paste into the EDIT Command Bar of the existing cloud place. Then File > Publish.')
$lines.Add('assert(not game:GetService("RunService"):IsRunning(),"Stop Play before syncing")')
$lines.Add("assert(game.PlaceId==$PlaceId and game.GameId==$UniverseId,`"Wrong cloud destination: open the existing TEST from Roblox`")")
$lines.Add(@'
local function folder(parent,name)
    local f=parent:FindFirstChild(name)
    if not f then f=Instance.new("Folder"); f.Name=name; f.Parent=parent end
    assert(f:IsA("Folder"),name); return f
end
local shared=folder(game.ReplicatedStorage,"SimulatorShared")
local server=folder(game.ServerScriptService,"Simulator")
local client=folder(game.StarterPlayer.StarterPlayerScripts,"SimulatorClient")
local function put(parent,class,name,source)
    local obj=parent:FindFirstChild(name)
    if not obj then obj=Instance.new(class); obj.Name=name; obj.Parent=parent end
    assert(obj.ClassName==class,name); obj.Source=source
    assert(obj.Source==source,name.." source mismatch")
end
'@)
$count=0
foreach($kind in @('shared','server','client')){
    foreach($file in (Get-ChildItem -LiteralPath (Join-Path $projectRoot "src/$kind") -Filter '*.lua' | Sort-Object Name)){
        $class=if($file.Name.EndsWith('.server.lua')){'Script'}elseif($file.Name.EndsWith('.client.lua')){'LocalScript'}else{'ModuleScript'}
        $name=$file.Name -replace '\.(server|client)\.lua$|\.lua$',''
        $source=[System.IO.File]::ReadAllText($file.FullName)
        $lines.Add(('put('+ $kind +',"'+$class+'","'+$name+'",'+(Quote-Luau $source)+')'))
        $count++
    }
}
$lines.Add("print(`"CLOUD_SOURCE_SYNC_PASS`",$count,game.PlaceId,game.GameId)")
[System.IO.File]::WriteAllText($OutputPath,($lines -join "`n"),(New-Object System.Text.UTF8Encoding($false)))
Write-Output "Prepared $count scripts: $OutputPath"
Write-Output 'This only prepares a file. It does not run Studio, upload or publish anything.'
