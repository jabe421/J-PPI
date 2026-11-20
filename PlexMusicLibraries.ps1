function Get-PlexMusicLibraries([uri] $Server, [string] $Token) {
    if (!$Server.IsAbsoluteUri -or $Server.Scheme -notin 'http', 'https' -or
        $Server.UserInfo -or $Server.Query -or $Server.Fragment) {
        throw 'Server must be an HTTP or HTTPS base URL.'
    }

    $baseUrl = $Server.AbsoluteUri.TrimEnd('/')
    $headers = @{ 'X-Plex-Token' = $Token; Accept = 'application/json' }
    $sections = Invoke-RestMethod -Uri "$baseUrl/library/sections" -Headers $headers -TimeoutSec 15 -MaximumRedirection 0 -ErrorAction Stop
    $sections.MediaContainer.Directory | Where-Object { $_.type -eq 'artist' }
}
