param([string]$SteamRoot='', [switch]$NoRestart, [switch]$CheckOnly, [string]$LocalPackage='')
$ErrorActionPreference='Stop'
$v1='https://github.com/DarkFireReal/DarkCoreRelease/releases/download/v2.0.3/DarkCore-Windows.zip'
$v2='50178aa44e2426625e5db87ce82e6dc2cbf8f9a97cbad0224fc9f6ed4494dda8'
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
[pscustomobject]@{SteamRoot=$SteamRoot;Version='2.0.3';Archive=$v1;SHA256=$v2}
return
}
if(![Environment]::Is64BitOperatingSystem) { throw 'DarkCore requires Windows x64.' }
if($v2 -notmatch '^[a-f0-9]{64}$') { throw 'This installer has not been prepared for release.' }
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$v5=Join-Path ([IO.Path]::GetTempPath()) ('DarkCore-'+[guid]::NewGuid().ToString('N'))
Plain-Path $v5
[IO.Directory]::CreateDirectory($v5) | Out-Null
function Digest($v3) {
$v6=[Security.Cryptography.SHA256]::Create();$v7=[IO.File]::OpenRead($v3)
try { ([BitConverter]::ToString($v6.ComputeHash($v7))).Replace('-','').ToLowerInvariant() }
finally { $v7.Dispose();$v6.Dispose() }
}
function Fetch-Verified($v8,$v3,$v9) {
if($v8 -notmatch '^https://github\.com/(DarkFireReal/DarkCoreRelease|SteamClientHomebrew/Installer)/releases/download/') { throw 'Unsupported download origin.' }
Invoke-WebRequest -Uri $v8 -OutFile $v3 -UseBasicParsing -TimeoutSec 180
if((Digest $v3) -ne $v9) { throw 'Download checksum mismatch. Nothing from this archive will be installed.' }
}
function Extract-Checked($va,$vb) {
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
[IO.Directory]::CreateDirectory($vb) | Out-Null
$vc=[IO.Path]::GetFullPath($vb).TrimEnd([char]92)+'\'
$vd=[IO.Compression.ZipFile]::OpenRead($va);$ve=0
$vf=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
try {
if($vd.Entries.Count -gt 1000) { throw 'Too many archive entries.' }
foreach($v10 in $vd.Entries) {
$v11=$v10.FullName
if(!$v11 -or $v11 -match '(^/|\\|:|[\x00-\x1f]|(^|/)\.{1,2}(/|$)|[. ](/|$)|(^|/)(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])([./]|$))' -or (($v10.ExternalAttributes -shr 16) -band 61440) -eq 40960) { throw 'Unsafe archive path.' }
$v12=[IO.Path]::GetFullPath((Join-Path $vb $v11))
if(!$v12.StartsWith($vc,[StringComparison]::OrdinalIgnoreCase) -or !$vf.Add($v12)) { throw 'Invalid or duplicate archive path.' }
$ve+=$v10.Length
if($ve -gt 64MB -or $v10.Length -gt 25MB) { throw 'Archive exceeds installation limits.' }
}
foreach($v10 in $vd.Entries) {
$v12=[IO.Path]::GetFullPath((Join-Path $vb $v10.FullName))
if($v10.FullName.EndsWith('/')) { [IO.Directory]::CreateDirectory($v12) | Out-Null;continue }
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($v12)) | Out-Null
[IO.Compression.ZipFileExtensions]::ExtractToFile($v10,$v12,$false)
}
} finally { $vd.Dispose() }
}
try {
$v13=Join-Path $v5 'DarkCore-Windows.zip'
if($LocalPackage) {
[IO.File]::Copy([IO.Path]::GetFullPath($LocalPackage),$v13)
if((Digest $v13) -ne $v2) { throw 'Local package checksum mismatch.' }
} else { Fetch-Verified $v1 $v13 $v2 }
$v14=Join-Path $v5 'package';Extract-Checked $v13 $v14
foreach($v15 in @('Install-DarkCore.ps1','Install-DarkFireRuntime.ps1','Native/SHA256SUMS.json')){if(!(Test-Path -LiteralPath (Join-Path $v14 $v15))){throw 'Incomplete DarkCore runtime package.'}}
if(!(Test-Path -LiteralPath (Join-Path $SteamRoot 'libmillennium.dll')) -and
!(Test-Path -LiteralPath (Join-Path $SteamRoot 'millennium/lib/millennium.dll'))) {
Write-Output 'Complete the official Millennium installation window, then DarkCore will continue.'
$v16=Join-Path $v5 'MillenniumInstaller.exe'
Fetch-Verified 'https://github.com/SteamClientHomebrew/Installer/releases/download/v1.12.1/MillenniumInstaller-Windows.exe' $v16 '1a3baf49f20c321bdcc9421f5b7aab8c1e8a33792c93086463d148b502c1be3d'
if((Get-AuthenticodeSignature -LiteralPath $v16).Status -ne 'Valid') { throw 'Millennium installer signature is invalid.' }
Start-Process -FilePath $v16 -Wait -WindowStyle Normal
if(!(Test-Path -LiteralPath (Join-Path $SteamRoot 'libmillennium.dll')) -and
!(Test-Path -LiteralPath (Join-Path $SteamRoot 'millennium/lib/millennium.dll'))) { throw 'Millennium installation was not completed.' }
}
& (Join-Path $v14 'Install-DarkCore.ps1') -SteamRoot $SteamRoot -NoRestart
& (Join-Path $v14 'Install-DarkFireRuntime.ps1') -SteamRoot $SteamRoot -NoRestart
if(!$NoRestart) { Start-Process -FilePath (Join-Path $SteamRoot 'steam.exe') -WindowStyle Hidden }
Write-Output 'DarkCore is ready. Sign in at https://darkcore.ccwu.cc and connect the plugin with a new token.'
} finally {
$v17=[IO.Path]::GetFullPath($v5);$v9=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char]92)+'\DarkCore-'
if(!$v17.StartsWith($v9,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe temporary cleanup path.' }
foreach($v10 in Get-ChildItem -LiteralPath $v17 -Recurse -Force) {
if($v10.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked temporary files will not be removed automatically.' }
}
Remove-Item -LiteralPath $v17 -Recurse -Force
}
