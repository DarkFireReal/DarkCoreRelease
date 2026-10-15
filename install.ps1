param([string]$SteamRoot='', [switch]$NoRestart, [switch]$CheckOnly, [string]$LocalPackage='')
$ErrorActionPreference='Stop'
$v1='https://github.com/DarkFireReal/DarkCoreRelease/releases/download/v2.0.2/DarkCore-Windows.zip'
$v2='c49708ba654f37d809434904ef9992b77a1754234f3d62090d7c1735749138b3'
if(!$SteamRoot) { $SteamRoot=(Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -Name SteamPath).SteamPath }
$SteamRoot=[IO.Path]::GetFullPath($SteamRoot).TrimEnd([char]92)
function Plain-Path($v3) {
$v4=[IO.Path]::GetFullPath($v3)
while($v4) {
if((Test-Path -LiteralPath $v4) -and ((Get-Item -LiteralPath $v4 -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Installation through links is unsupported.' }
$v4=[IO.Path]::GetDirectoryName($v4)
}
}
Plain-Path $SteamRoot
if(!(Test-Path -LiteralPath (Join-Path $SteamRoot 'steam.exe'))) { throw 'Steam was not found.' }
if($CheckOnly) {
[pscustomobject]@{SteamRoot=$SteamRoot;Version='2.0.2';Archive=$v1;SHA256=$v2}
return
}
if(![Environment]::Is64BitOperatingSystem) { throw 'DarkCore requires Windows x64.' }
if($v2 -notmatch '^[a-f0-9]{64}$') { throw 'This installer has not been prepared for release.' }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$v5=Join-Path ([IO.Path]::GetTempPath()) ('DarkCore-'+[guid]::NewGuid().ToString('N'))
Plain-Path $v5
[IO.Directory]::CreateDirectory($v5) | Out-Null
$v6=@();$v7=$false
function Digest($v3) {
$v8=[Security.Cryptography.SHA256]::Create();$v9=[IO.File]::OpenRead($v3)
try { ([BitConverter]::ToString($v8.ComputeHash($v9))).Replace('-','').ToLowerInvariant() }
finally { $v9.Dispose();$v8.Dispose() }
}
function Fetch-Verified($va,$v3,$vb) {
if($va -notmatch '^https://github\.com/(DarkFireReal/DarkCoreRelease|SteamClientHomebrew/Installer|madoiscool/BetterSteamTools)/releases/download/') { throw 'Unsupported download origin.' }
Invoke-WebRequest -Uri $va -OutFile $v3 -UseBasicParsing -TimeoutSec 180
if((Digest $v3) -ne $vb) { throw 'Download checksum mismatch. Nothing from this archive will be installed.' }
}
function Extract-Checked($vc,$vd) {
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
[IO.Directory]::CreateDirectory($vd) | Out-Null
$ve=[IO.Path]::GetFullPath($vd).TrimEnd([char]92)+'\'
$vf=[IO.Compression.ZipFile]::OpenRead($vc);$v10=0
$v11=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
try {
if($vf.Entries.Count -gt 1000) { throw 'Too many archive entries.' }
foreach($v12 in $vf.Entries) {
$v13=$v12.FullName
if(!$v13 -or $v13 -match '(^/|\\|:|[\x00-\x1f]|(^|/)\.{1,2}(/|$)|[. ](/|$)|(^|/)(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])([./]|$))' -or (($v12.ExternalAttributes -shr 16) -band 61440) -eq 40960) { throw 'Unsafe archive path.' }
$v14=[IO.Path]::GetFullPath((Join-Path $vd $v13))
if(!$v14.StartsWith($ve,[StringComparison]::OrdinalIgnoreCase) -or !$v11.Add($v14)) { throw 'Invalid or duplicate archive path.' }
$v10+=$v12.Length
if($v10 -gt 64MB -or $v12.Length -gt 25MB) { throw 'Archive exceeds installation limits.' }
}
foreach($v12 in $vf.Entries) {
$v14=[IO.Path]::GetFullPath((Join-Path $vd $v12.FullName))
if($v12.FullName.EndsWith('/')) { [IO.Directory]::CreateDirectory($v14) | Out-Null;continue }
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($v14)) | Out-Null
[IO.Compression.ZipFileExtensions]::ExtractToFile($v12,$v14,$false)
}
} finally { $vf.Dispose() }
}
try {
$v15=Join-Path $v5 'DarkCore-Windows.zip'
if($LocalPackage) {
[IO.File]::Copy([IO.Path]::GetFullPath($LocalPackage),$v15)
if((Digest $v15) -ne $v2) { throw 'Local package checksum mismatch.' }
} else { Fetch-Verified $v1 $v15 $v2 }
$v16=Join-Path $v5 'package';Extract-Checked $v15 $v16
if(!(Test-Path -LiteralPath (Join-Path $SteamRoot 'libmillennium.dll')) -and
!(Test-Path -LiteralPath (Join-Path $SteamRoot 'millennium/lib/millennium.dll'))) {
Write-Output 'Complete the official Millennium installation window, then DarkCore will continue.'
$v17=Join-Path $v5 'MillenniumInstaller.exe'
Fetch-Verified 'https://github.com/SteamClientHomebrew/Installer/releases/download/v1.12.1/MillenniumInstaller-Windows.exe' $v17 '1a3baf49f20c321bdcc9421f5b7aab8c1e8a33792c93086463d148b502c1be3d'
if((Get-AuthenticodeSignature -LiteralPath $v17).Status -ne 'Valid') { throw 'Millennium installer signature is invalid.' }
Start-Process -FilePath $v17 -Wait -WindowStyle Normal
if(!(Test-Path -LiteralPath (Join-Path $SteamRoot 'libmillennium.dll')) -and
!(Test-Path -LiteralPath (Join-Path $SteamRoot 'millennium/lib/millennium.dll'))) { throw 'Millennium installation was not completed.' }
}
$v18=@{
'OpenSteamTool.dll'='fe849c7e2b532e4e54f2d0bdce94e03f0aeffe69a64e9601a775f16fab6cdef7'
'dwmapi.dll'='e1d026e903f38fed22c82be137a92cf30b1848621f6f7977c1a3e4d389687aab'
'xinput1_4.dll'='4e635c3e02d0687898342299fcb9ed698bfd2ae8ae64b3dada47ebc5dce359f7'
}
$v19=@($v18.Keys | Where-Object { !(Test-Path -LiteralPath (Join-Path $SteamRoot $_)) })
if($v19.Count) {
foreach($v13 in $v18.Keys) {
$v1a=Join-Path $SteamRoot $v13
if((Test-Path -LiteralPath $v1a) -and (Digest $v1a) -ne $v18[$v13]) { throw "Existing dependency differs: $v13. Preserve it and contact the administrator." }
}
$v1b=Join-Path $v5 'dependency.zip';$v1c=Join-Path $v5 'dependency'
Fetch-Verified 'https://github.com/madoiscool/BetterSteamTools/releases/download/v1.0.4/OpenSteamTool-v1.0.4-Release.zip' $v1b '06a32ffbf86dbb281eefb143dc4d90a7710889aed550cc923c4ccdc5a8455e34'
Extract-Checked $v1b $v1c
foreach($v13 in $v18.Keys) { if((Digest (Join-Path $v1c $v13)) -ne $v18[$v13]) { throw 'Dependency file checksum mismatch.' } }
foreach($v13 in $v19) {
$v14=Join-Path $SteamRoot $v13;Plain-Path $v14
[IO.File]::Copy((Join-Path $v1c $v13),$v14,$false)
$v6+=@{path=$v14;hash=$v18[$v13]}
}
}
$v1d=Join-Path $SteamRoot 'opensteamtool.toml'
Plain-Path $v1d
if(!(Test-Path -LiteralPath $v1d)) {
[IO.File]::WriteAllText($v1d,"[lua]`npaths = [`"config/stplug-in`"]`n",[Text.UTF8Encoding]::new($false))
$v6+=@{path=$v1d;hash=(Digest $v1d)}
} elseif([IO.File]::ReadAllText($v1d) -notmatch '(?i)config[/\\]stplug-in') {
throw 'The existing Lua configuration must include config/stplug-in. Contact the administrator.'
}
& (Join-Path $v16 'Install-DarkCore.ps1') -SteamRoot $SteamRoot -NoRestart
$v7=$true
if(!$NoRestart) { Start-Process -FilePath (Join-Path $SteamRoot 'steam.exe') -WindowStyle Hidden }
Write-Output 'DarkCore is ready. Sign in at https://darkcore.ccwu.cc and connect the plugin with a new token.'
} finally {
if(!$v7) {
foreach($v12 in $v6) {
Plain-Path $v12.path
if((Test-Path -LiteralPath $v12.path) -and (Digest $v12.path) -eq $v12.hash) { Remove-Item -LiteralPath $v12.path -Force }
}
}
$v1e=[IO.Path]::GetFullPath($v5);$vb=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char]92)+'\DarkCore-'
if(!$v1e.StartsWith($vb,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe temporary cleanup path.' }
foreach($v12 in Get-ChildItem -LiteralPath $v1e -Recurse -Force) {
if($v12.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked temporary files will not be removed automatically.' }
}
Remove-Item -LiteralPath $v1e -Recurse -Force
}
