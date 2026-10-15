$ErrorActionPreference = 'Stop'
$doc = New-Object System.Xml.XmlDocument
$root = $doc.CreateElement('roblox')
$root.SetAttribute('version', '4')
$null = $doc.AppendChild($root)
function Add-Property($item, [string]$type, [string]$name, [string]$value) {
    $prop = $doc.CreateElement($type)
    $prop.SetAttribute('name', $name)
    $prop.InnerText = $value
    $null = $item.SelectSingleNode('Properties').AppendChild($prop)
}
function Add-Item($parent, [string]$class, [string]$name) {
    $item = $doc.CreateElement('Item')
    $item.SetAttribute('class', $class)
    $item.SetAttribute('referent', 'RBX' + [guid]::NewGuid().ToString('N'))
    $null = $parent.AppendChild($item)
    $properties = $doc.CreateElement('Properties')
    $null = $item.AppendChild($properties)
    Add-Property $item 'string' 'Name' $name
    return ,$item
}
function Add-Script($parent, $class, $name, $relativePath) {
    $item = Add-Item $parent $class $name
    Add-Property $item 'ProtectedString' 'Source' ([System.IO.File]::ReadAllText((Join-Path $PSScriptRoot $relativePath)))
    return ,$item
}
function Add-Vector($item, [string]$name, $values) {
    $prop = $doc.CreateElement('Vector3'); $prop.SetAttribute('name',$name)
    for ($i=0; $i -lt 3; $i++) {
        $node=$doc.CreateElement(@('X','Y','Z')[$i]); $node.InnerText=[string]$values[$i]; $null=$prop.AppendChild($node)
    }
    $null=$item.SelectSingleNode('Properties').AppendChild($prop)
}
function Add-CFrame($item, $position) {
    $prop=$doc.CreateElement('CoordinateFrame'); $prop.SetAttribute('name','CFrame')
    $keys=@('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22')
    $values=@($position[0],$position[1],$position[2],1,0,0,0,1,0,0,0,1)
    for($i=0; $i -lt $keys.Count; $i++) {
        $node=$doc.CreateElement($keys[$i]); $node.InnerText=[string]$values[$i]; $null=$prop.AppendChild($node)
    }
    $null=$item.SelectSingleNode('Properties').AppendChild($prop)
}
function Add-Part($parent,$name,$size,$position,$color,[string]$class='Part') {
    $part=Add-Item $parent $class $name
    Add-Property $part 'bool' 'Anchored' 'true'
    Add-Property $part 'bool' 'CanCollide' 'true'
    Add-Property $part 'token' 'TopSurface' '0'
    Add-Property $part 'token' 'BottomSurface' '0'
    Add-Property $part 'Color3uint8' 'Color3uint8' ([string](4278190080L+$color[0]*65536L+$color[1]*256L+$color[2]))
    Add-Vector $part 'size' $size
    Add-CFrame $part $position
    return ,$part
}
$workspace = Add-Item $root 'Workspace' 'Workspace'
$null = Add-Item $workspace 'Terrain' 'Terrain'
# Lightweight editor preview. World.Build recreates the complete scene during Play.
$preview=Add-Item $workspace 'Folder' 'SimulatorWorld'
$null=Add-Part $preview 'Ground' @(100,2,80) @(4,-1,0) @(30,40,62)
$null=Add-Part $preview 'StartingPlaza' @(32,0.2,26) @(-12,0.1,0) @(47,72,88)
$null=Add-Part $preview 'AdvancedPlaza' @(28,0.2,26) @(24,0.1,0) @(67,49,96)
$null=Add-Part $preview 'Path' @(6,0.2,7) @(7,0.05,0) @(100,109,134)
$null=Add-Part $preview 'Basic' @(8,1,8) @(-16,1,0) @(65,220,183)
$null=Add-Part $preview 'Advanced' @(8,1,8) @(24,1,0) @(160,116,255)
# No visible spawn platform, including the editor preview. Runtime relocates to Config.SpawnPosition.
$null = Add-Item $root 'Players' 'Players'
$lighting = Add-Item $root 'Lighting' 'Lighting'
Add-Property $lighting 'float' 'ClockTime' '14'
Add-Property $lighting 'float' 'Brightness' '2'
$replicated = Add-Item $root 'ReplicatedStorage' 'ReplicatedStorage'
$shared = Add-Item $replicated 'Folder' 'SimulatorShared'
$null = Add-Script $shared 'ModuleScript' 'Config' 'src\shared\Config.lua'
$null = Add-Script $shared 'ModuleScript' 'NumberFormat' 'src\shared\NumberFormat.lua'
$null = Add-Script $shared 'ModuleScript' 'TextStyle' 'src\shared\TextStyle.lua'
$null = Add-Script $shared 'ModuleScript' 'ModelFactory' 'src\shared\ModelFactory.lua'
$server = Add-Item $root 'ServerScriptService' 'ServerScriptService'
$modules = Add-Item $server 'Folder' 'Simulator'
foreach ($name in @('Schema','PlayerData','Progression','Rebirth','Rewards','Pets','PetVisuals','Security','LeaderboardTemplate','World','Network','Telemetry','Runtime')) {
    $null = Add-Script $modules 'ModuleScript' $name "src\server\$name.lua"
}
$null = Add-Script $modules 'Script' 'Bootstrap' 'src\server\Bootstrap.server.lua'
$tests = Add-Item $modules 'Folder' 'Tests'
$null = Add-Script $tests 'ModuleScript' 'Spec' 'tests\Spec.lua'
$null = Add-Script $tests 'ModuleScript' 'Integration' 'tests\StudioIntegration.lua'
$starter = Add-Item $root 'StarterPlayer' 'StarterPlayer'
$scripts = Add-Item $starter 'StarterPlayerScripts' 'StarterPlayerScripts'
$client = Add-Item $scripts 'Folder' 'SimulatorClient'
$null = Add-Script $client 'ModuleScript' 'UI' 'src\client\UI.lua'
$null = Add-Script $client 'ModuleScript' 'Glass' 'src\client\Glass.lua'
$null = Add-Script $client 'ModuleScript' 'Headings' 'src\client\Headings.lua'
$null = Add-Script $client 'ModuleScript' 'Settings' 'src\client\Settings.lua'
$null = Add-Script $client 'ModuleScript' 'PetCatalog' 'src\client\PetCatalog.lua'
$null = Add-Script $client 'ModuleScript' 'Presentation' 'src\client\Presentation.lua'
$null = Add-Script $client 'LocalScript' 'Controller' 'src\client\Controller.client.lua'
$null = Add-Script $client 'LocalScript' 'WorldSigns' 'src\client\WorldSigns.client.lua'
$null = Add-Item $root 'StarterGui' 'StarterGui'
$outputPath = Join-Path $PSScriptRoot 'SimulatorMVP.rbxlx'
$doc.Save($outputPath)
Write-Output "Built: $outputPath"
Write-Output 'Open in Studio and press Play. World and UI are built automatically.'
