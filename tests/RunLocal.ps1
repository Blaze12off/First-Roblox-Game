$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$compiler=Join-Path $projectRoot 'tools\luau-0.741\luau-compile.exe'
$runtime=Join-Path $projectRoot 'tools\luau-0.741\luau.exe'
if(-not(Test-Path -LiteralPath $compiler)){throw 'Official Luau 0.741 CLI missing from tools/luau-0.741'}
$files=@(Get-ChildItem (Join-Path $projectRoot 'src'),$PSScriptRoot -Recurse -Filter '*.lua' | Where-Object {$_.Name -ne '_local_harness.lua'})
foreach($file in $files){
    & $compiler --null $file.FullName
    if($LASTEXITCODE -ne 0){throw "Compilation failed: $($file.FullName)"}
}
Write-Output "LUAU_COMPILE_PASS $($files.Count) sources"
$header=@'
-- Generated test adapter. Roblox engine and DataStore network are NOT simulated as verified.
local moduleFactories,cache={},{}
local getModule
local root={}
for _,name in {"Schema","PlayerData","Progression","Rebirth","Rewards","Security","Pets"} do root[name]=name end
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end,zero={X=0,Y=0,Z=0}}
local nextGuid=0
local Http={GenerateGUID=function() nextGuid+=1; return "test-guid-"..nextGuid end}
local game={ReplicatedStorage={SimulatorShared={Config="Config",NumberFormat="NumberFormat"}},ServerScriptService={Simulator=root}}
function game:GetService(name) assert(name=="HttpService","unexpected engine service"); return Http end
local task={wait=function() error("Unexpected real task.wait in unit tests") end}
'@
$builder=New-Object System.Text.StringBuilder
$null=$builder.AppendLine($header)
$sources=[ordered]@{NumberFormat='src\shared\NumberFormat.lua';Config='src\shared\Config.lua';Schema='src\server\Schema.lua';PlayerData='src\server\PlayerData.lua';Progression='src\server\Progression.lua';Rebirth='src\server\Rebirth.lua';Rewards='src\server\Rewards.lua';Security='src\server\Security.lua';Pets='src\server\Pets.lua';Spec='tests\Spec.lua'}
foreach($name in $sources.Keys){
    $null=$builder.AppendLine(('moduleFactories["'+$name+'"] = function()'))
    $null=$builder.AppendLine('local require=getModule; local script={Parent=root}')
    $null=$builder.AppendLine([System.IO.File]::ReadAllText((Join-Path $projectRoot $sources[$name])))
    $null=$builder.AppendLine('end')
}
$null=$builder.AppendLine(@'
getModule=function(name)
    if cache[name] then return cache[name] end
    assert(moduleFactories[name],"Missing module: "..tostring(name))
    cache[name]=moduleFactories[name]()
    return cache[name]
end
getModule("Spec").Run()
'@)
$harness=Join-Path $PSScriptRoot '_local_harness.lua'
[System.IO.File]::WriteAllText($harness,$builder.ToString(),(New-Object System.Text.UTF8Encoding($false)))
& $runtime $harness
if($LASTEXITCODE -ne 0){throw 'Unit suite failed'}
& $runtime (Join-Path $PSScriptRoot 'NumberFormat.spec.lua')
if($LASTEXITCODE -ne 0){throw 'Number formatting suite failed'}
$auditSource=[System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'HatchRandomness.spec.lua'))
$audit=Join-Path $PSScriptRoot '_hatch_randomness.tmp'
$auditCode=$builder.ToString()+"`nlocal audit=(function()`n"+$auditSource+"`nend)()`naudit(getModule(`"Config`"),getModule(`"Schema`"),getModule(`"Pets`"))`n"
[System.IO.File]::WriteAllText($audit,$auditCode,(New-Object System.Text.UTF8Encoding($false)))
& $runtime $audit
if($LASTEXITCODE -ne 0){throw 'Hatch distribution audit failed'}
