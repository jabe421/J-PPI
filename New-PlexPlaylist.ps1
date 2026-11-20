[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]] $TrackPath,

    [Parameter(Mandatory)]
    [string] $OutputPath,

    [switch] $Import,

    [switch] $Overwrite,

    [string] $LibraryName = 'Music',

    [uri] $Server = 'http://localhost:32400',

    [securestring] $PlexToken
)

$ErrorActionPreference = 'Stop'

if ([IO.Path]::GetExtension($OutputPath) -ine '.m3u') {
    throw 'OutputPath must end in .m3u.'
}

$playlistPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$entries = foreach ($path in $TrackPath) {
    $track = Get-Item -LiteralPath $path
    if ($track -isnot [IO.FileInfo]) {
        throw "Expected a track file at '$path'."
    }
    if ($track.FullName -match '[\r\n]') {
        throw "Track paths cannot contain line breaks."
    }
    $track.FullName
}

if ($Import) {
    . "$PSScriptRoot/PlexMusicLibraries.ps1"
    $token = $env:PLEX_TOKEN
    if ($PlexToken) {
        $token = [System.Net.NetworkCredential]::new('', $PlexToken).Password
    }
    if ([string]::IsNullOrWhiteSpace($token)) {
        $secret = Read-Host 'Plex token for the account you use in Plexamp' -AsSecureString
        $token = [System.Net.NetworkCredential]::new('', $secret).Password
    }
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw 'A Plex token is required to import a playlist.'
    }

    $libraries = @(Get-PlexMusicLibraries $Server $token | Where-Object { $_.title -eq $LibraryName })
    if ($libraries.Count -ne 1) {
        throw "Expected one Plex music library named '$LibraryName', found $($libraries.Count). Use -LibraryName to select a library."
    }
}

$tempName = [guid]::NewGuid().ToString('N') + '.tmp'
$tempPath = [IO.Path]::Combine([IO.Path]::GetDirectoryName($playlistPath), $tempName)
try {
    $content = "#EXTM3U`r`n" + ($entries -join "`r`n") + "`r`n"
    [IO.File]::WriteAllText($tempPath, $content)
    if ($Overwrite -and [IO.File]::Exists($playlistPath)) {
        [IO.File]::Replace($tempPath, $playlistPath, [System.Management.Automation.Language.NullString]::Value)
    } else {
        [IO.File]::Move($tempPath, $playlistPath)
    }
}
finally {
    [IO.File]::Delete($tempPath)
}

Write-Output "Created $playlistPath"

if ($Import) {
    $baseUrl = $Server.AbsoluteUri.TrimEnd('/')
    $headers = @{ 'X-Plex-Token' = $token; Accept = 'application/json' }
    $encodedPath = [uri]::EscapeDataString($playlistPath)
    $sectionId = [uri]::EscapeDataString([string] $libraries[0].key)
    $importUri = "$baseUrl/playlists/upload?sectionID=$sectionId&path=$encodedPath&force=0"
    Invoke-RestMethod -Method Post -Uri $importUri -Headers $headers -TimeoutSec 120 -MaximumRedirection 0 | Out-Null
    Write-Output "Plex accepted the import for '$LibraryName'. Check Playlists in Plexamp."
}
