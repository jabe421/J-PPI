Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$appTitle = "Jabe's Plex Playlist Importer"
$appDirectory = $PSScriptRoot
$iconPath = Join-Path $appDirectory 'J-PPI.ico'
$appIcon = if ([IO.File]::Exists($iconPath)) { [Drawing.Icon]::new($iconPath) }

function Set-AppWindowIdentity([Windows.Forms.Form] $window, [string] $title = $appTitle) {
    $window.Text = $title
    if ($appIcon) { $window.Icon = $appIcon }
}

$form = [Windows.Forms.Form]::new()
Set-AppWindowIdentity $form 'J-PPI'
$form.ClientSize = [Drawing.Size]::new(1120, 591)
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.StartPosition = 'CenterScreen'

$menu = [Windows.Forms.MenuStrip]::new()
$helpMenu = $menu.Items.Add('&Help')
$guide = $helpMenu.DropDownItems.Add('&User Guide')
$about = $helpMenu.DropDownItems.Add('&About J-PPI')
$form.MainMenuStrip = $menu
$form.Controls.Add($menu)

function Add-Control($type, $caption, $x, $y, $width, $height, $left = $false) {
    $control = New-Object "System.Windows.Forms.$type"
    $control.Text = $caption
    if (!$left) { $x += 400 }
    $control.SetBounds($x, ($y + 26), $width, $height)
    $form.Controls.Add($control)
    $control
}

$null = Add-Control Label 'Tracks (in playback order)' 16 16 500 22
$appVersion = [version] '0.1.0'


function Get-ReleaseRepository {
    $repository = $env:JPPI_GITHUB_REPO
    if (!$repository -and (Get-Command git -ErrorAction SilentlyContinue)) {
        $origin = git -C $appDirectory config --get remote.origin.url 2>$null
        if ($origin -match '^(?:https://github\.com/|git@github\.com:|ssh://git@github\.com/)(?<repo>[\w.-]+/[\w.-]+?)(?:\.git)?/?$') {
            $repository = $Matches.repo
        }
    }
    if (!$repository) { $repository = 'jabe421/J-PPI' }
    if ($repository -match '^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$') { $repository }
}

function Show-HelpText([string] $title, [string] $content) {
    $notes = [Windows.Forms.Form]::new()
    try {
        Set-AppWindowIdentity $notes $title
        $notes.StartPosition = 'CenterParent'
        $notes.ClientSize = [Drawing.Size]::new(620, 375)
        $body = [Windows.Forms.TextBox]::new()
        $body.Multiline = $true
        $body.ReadOnly = $true
        $body.ScrollBars = 'Vertical'
        $body.Dock = 'Fill'
        $body.Text = $content -replace '\r?\n', "`r`n"
        $notes.Controls.Add($body)
        $notes.ShowDialog($form) | Out-Null
    }
    finally { $notes.Dispose() }
}

$guide.Add_Click({
    $content = Get-Content -Raw -LiteralPath (Join-Path $appDirectory 'USER-GUIDE.txt')
    Show-HelpText $appTitle $content
})

$about.Add_Click({
    $dialog = [Windows.Forms.Form]::new()
    try {
        Set-AppWindowIdentity $dialog
        $dialog.StartPosition = 'CenterParent'
        $dialog.FormBorderStyle = 'FixedSingle'
        $dialog.MaximizeBox = $false
        $dialog.MinimizeBox = $false
        $dialog.ClientSize = [Drawing.Size]::new(520, 384)
        $description = [Windows.Forms.Label]::new()
        $description.SetBounds(12, 10, 496, 72)
        $description.Text = "J-PPI (Jabe's Plex Playlist Importer) is a Windows app for creating and editing music playlists. You can search your music folders, arrange tracks, and open existing .m3u playlists to find and replace missing songs. You can then save the playlist as an .m3u file or import it into Plex Media Server for playback in Plexamp."
        $dialog.Controls.Add($description)
        $heading = [Windows.Forms.Label]::new()
        $heading.SetBounds(12, 88, 496, 22)
        $heading.Text = "Current version: $appVersion"
        $dialog.Controls.Add($heading)
        $newest = [Windows.Forms.Label]::new()
        $newest.SetBounds(12, 111, 496, 22)
        $newest.Text = 'Newest available version: Unknown'
        $dialog.Controls.Add($newest)
        $message = [Windows.Forms.Label]::new()
        $message.SetBounds(12, 135, 496, 23)
        $dialog.Controls.Add($message)
        $notes = [Windows.Forms.TextBox]::new()
        $notes.SetBounds(12, 159, 496, 180)
        $notes.Multiline = $true
        $notes.ReadOnly = $true
        $notes.ScrollBars = 'Vertical'
        $currentNotes = (Get-Content -Raw -LiteralPath (Join-Path $appDirectory 'RELEASE-NOTES.md')) -replace '\r?\n', "`r`n"
        $notes.Text = $currentNotes
        $dialog.Controls.Add($notes)
        $check = [Windows.Forms.Button]::new()
        $check.SetBounds(12, 346, 160, 27)
        $check.Text = 'Check Again'
        $dialog.Controls.Add($check)
        $download = [Windows.Forms.Button]::new()
        $download.SetBounds(180, 346, 160, 27)
        $download.Text = 'Update'
        $download.Enabled = $false
        $dialog.Controls.Add($download)
        $close = [Windows.Forms.Button]::new()
        $close.SetBounds(348, 346, 160, 27)
        $close.Text = 'Exit'
        $close.DialogResult = 'Cancel'
        $dialog.CancelButton = $close
        $dialog.Controls.Add($close)
        $update = @{ Url = $null }
        $download.Add_Click({ Start-Process $update.Url })
        $check.Add_Click({
            $download.Enabled = $false
            $newest.Text = 'Newest available version: Unknown'
            $notes.Text = $currentNotes
            $repo = Get-ReleaseRepository
            if (!$repo) {
                $message.Text = 'No GitHub release repository is configured for this copy of J-PPI.'
                return
            }
            $message.Text = 'Checking GitHub for the latest release...'
            $message.Refresh()
            try {
                $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UserAgent 'J-PPI' -TimeoutSec 8 -ErrorAction Stop
                if ($release.tag_name -notmatch '^v?(?<version>\d+\.\d+\.\d+)$') {
                    $message.Text = 'No matching J-PPI releases have been published.'
                    return
                }
                $label = $Matches.version
                $latestVersion = [version] $label
                $newest.Text = "Newest available version: $label"
                if ($latestVersion -le $appVersion) {
                    $message.Text = "J-PPI $appVersion is up to date."
                    return
                }
                $tag = [uri]::EscapeDataString($release.tag_name)
                $update.Url = "https://github.com/$repo/releases/tag/$tag"
                $download.Enabled = $true
                $message.Text = 'Update opens the GitHub release page.'
                $notes.Text = $release.body -replace '\r?\n', "`r`n"
            }
            catch {
                $message.Text = 'Could not find a published J-PPI release. Check the repository and try again.'
            }
        })
        $dialog.Add_Shown({ $check.PerformClick() })
        $dialog.ShowDialog($form) | Out-Null
    }
    finally { $dialog.Dispose() }
})
$tracks = Add-Control ListBox '' 16 42 688 232
$tracks.HorizontalScrollbar = $true
$tracks.DrawMode = 'OwnerDrawFixed'
$missingTracks = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$tracks.Add_DrawItem({
    param($sender, $eventArgs)
    if ($eventArgs.Index -lt 0) { return }
    $path = [string] $sender.Items[$eventArgs.Index]
    if ($missingTracks.Contains($path)) {
        $selected = $eventArgs.State.HasFlag([Windows.Forms.DrawItemState]::Selected)
        $background = if ($selected) { [Drawing.Brushes]::DarkRed } else { [Drawing.Brushes]::MistyRose }
        $foreground = if ($selected) { [Drawing.Color]::White } else { [Drawing.Color]::DarkRed }
        $eventArgs.Graphics.FillRectangle($background, $eventArgs.Bounds)
        $label = "[Missing] $path"
    } else {
        $eventArgs.DrawBackground()
        $foreground = $eventArgs.ForeColor
        $label = $path
    }
    $flags = [Windows.Forms.TextFormatFlags]'Left, VerticalCenter, SingleLine, NoPrefix'
    [Windows.Forms.TextRenderer]::DrawText($eventArgs.Graphics, $label, $eventArgs.Font, $eventArgs.Bounds, $foreground, $flags)
    $eventArgs.DrawFocusRectangle()
})
$repair = Add-Control Button 'Search for Missing Files' 16 280 160 30
$repair.Visible = $false
$add = Add-Control Button 'Add tracks...' 16 280 112 30
$remove = Add-Control Button 'Remove' 136 280 96 30
$up = Add-Control Button 'Move up' 240 280 96 30
$down = Add-Control Button 'Move down' 344 280 96 30
$trackButtons = @($add, $remove, $up, $down)
$trackButtonPositions = @($trackButtons | ForEach-Object { $_.Left })

$null = Add-Control Label 'Plex server URL' 16 329 120 22
$settingsFolder = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'J-PPI'
$searchFolderSetting = Join-Path $settingsFolder 'search-folder.txt'
$serverUrlSetting = Join-Path $settingsFolder 'plex-server-url.txt'
$musicLibrarySetting = Join-Path $settingsFolder 'music-library.txt'

function Get-SavedSetting([string] $path, [string] $defaultValue) {
    try {
        if ([IO.File]::Exists($path)) { return [IO.File]::ReadAllText($path) }
    } catch {
        Write-Verbose "Could not read the setting: $($_.Exception.Message)"
    }
    $defaultValue
}

function Test-RememberedServerUrl([string] $value) {
    $address = $null
    [uri]::TryCreate($value, [UriKind]::Absolute, [ref] $address) -and
        $address.Scheme -in 'http', 'https' -and $address.Host -and
        !$address.UserInfo -and !$address.Query -and !$address.Fragment
}

$localServerUrl = 'http://localhost:32400'
$savedServerUrl = Get-SavedSetting $serverUrlSetting $localServerUrl
if (!(Test-RememberedServerUrl $savedServerUrl)) { $savedServerUrl = $localServerUrl }
$server = Add-Control TextBox $savedServerUrl 146 325 558 24
$null = Add-Control Label 'Music library' 16 363 120 22
$library = Add-Control ComboBox (Get-SavedSetting $musicLibrarySetting 'Music') 146 359 420 24
$refreshLibraries = Add-Control Button 'Refresh libraries' 575 357 129 28
$null = Add-Control Label 'Plex token' 16 397 120 22
$token = Add-Control TextBox '' 146 393 558 24
$token.UseSystemPasswordChar = $true
$tokenHint = Add-Control Label 'Use the token for the account you use in Plexamp.' 146 423 558 24

function Get-LocalPlexToken {
    $settings = Get-ItemProperty -LiteralPath 'HKCU:\Software\Plex, Inc.\Plex Media Server' `
        -Name PlexOnlineToken -ErrorAction SilentlyContinue
    $settings.PlexOnlineToken
}

$localPlexToken = Get-LocalPlexToken
if ($server.Text.TrimEnd('/') -ieq $localServerUrl -and ![string]::IsNullOrWhiteSpace($localPlexToken)) {
    $token.Text = $localPlexToken
    $tokenHint.Text = 'Loaded from the local Plex server registry. Use your own token for a different Plex account.'
}

$server.Add_TextChanged({
    if ($localPlexToken -and $token.Text -ceq $localPlexToken -and
        $server.Text.Trim().TrimEnd('/') -ine $localServerUrl) {
        $token.Clear()
        $tokenHint.Text = 'Enter the token for the selected Plex server and account.'
    }
})

$open = Add-Control Button 'Open .m3u...' 16 458 115 34
$save = Add-Control Button 'Save .m3u...' 139 458 145 34
$import = Add-Control Button 'Save and import...' 292 458 155 34
$status = Add-Control Label 'Add audio files to get started.' 16 508 688 45
$libraryStatus = Add-Control Label '' 16 537 688 22
$status.Height = 28

$libraryTimer = [Windows.Forms.Timer]::new()
$libraryTimer.Interval = 300
$libraryState = @{ Dirty = $true; Changed = [datetime]::UtcNow; Worker = $null; Pending = $null }
$libraryHelper = Join-Path $PSScriptRoot 'PlexMusicLibraries.ps1'

function Request-LibraryRefresh {
    $preferredLibrary = $library.Text
    $library.Items.Clear()
    $library.Text = $preferredLibrary
    $libraryState.Dirty = $true
    $libraryState.Changed = [datetime]::UtcNow
}
$server.Add_TextChanged({ Request-LibraryRefresh })
$token.Add_TextChanged({ Request-LibraryRefresh })
$refreshLibraries.Add_Click({ Request-LibraryRefresh })

$libraryTimer.Add_Tick({
    if ($libraryState.Worker) {
        if (!$libraryState.Pending.IsCompleted) { return }
        try {
            $names = @($libraryState.Worker.EndInvoke($libraryState.Pending))
            if (!$libraryState.Dirty) {
                $library.Items.AddRange([object[]] $names)
                $preferredIndex = $library.FindStringExact($library.Text)
                if ($preferredIndex -ge 0) {
                    $library.SelectedIndex = $preferredIndex
                } elseif ($names.Count -gt 0) {
                    $library.SelectedIndex = 0
                }
                $libraryStatus.Text = if ($names.Count -eq 1) {
                    'Found 1 Plex music library.'
                } elseif ($names.Count -gt 1) {
                    "Found $($names.Count) Plex music libraries."
                } else { 'No music libraries found for this Plex account.' }
            }
        }
        catch {
            if (!$libraryState.Dirty) {
                $libraryStatus.Text = 'Could not load music libraries. Check the Plex server URL and token.'
            }
        }
        finally {
            $libraryState.Worker.Dispose()
            $libraryState.Worker = $null
        }
    }

    if (!$libraryState.Dirty -or ([datetime]::UtcNow - $libraryState.Changed).TotalMilliseconds -lt 650) { return }
    $libraryState.Dirty = $false
    $serverAddress = $server.Text.Trim()
    $credential = $token.Text.Trim()
    if (!$credential -and $serverAddress.TrimEnd('/') -ieq $localServerUrl) { $credential = $env:PLEX_TOKEN }
    if (!$credential -or !$serverAddress) {
        $libraryStatus.Text = 'Enter a Plex server URL and token to find music libraries.'
        return
    }

    $worker = [powershell]::Create()
    $null = $worker.AddScript({
        param($helper, $address, $credential)
        $ErrorActionPreference = 'Stop'
        . $helper
        Get-PlexMusicLibraries $address $credential |
            Select-Object -ExpandProperty title | Sort-Object -Unique
    }).AddArgument($libraryHelper).AddArgument($serverAddress).AddArgument($credential)
    $libraryState.Worker = $worker
    $libraryState.Pending = $worker.BeginInvoke()
    $libraryStatus.Text = 'Looking up Plex music libraries...'
})

$null = Add-Control Label 'Search folder' 16 16 372 22 $true
$defaultMusicFolder = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyMusic)
$searchPath = Add-Control TextBox (Get-SavedSetting $searchFolderSetting $defaultMusicFolder) 16 42 291 24 $true
$form.Add_FormClosed({
    try {
        [IO.Directory]::CreateDirectory($settingsFolder) | Out-Null
        [IO.File]::WriteAllText($searchFolderSetting, $searchPath.Text.Trim())
        if (![string]::IsNullOrWhiteSpace($library.Text)) {
            [IO.File]::WriteAllText($musicLibrarySetting, $library.Text.Trim())
        }
        $enteredUrl = $server.Text.Trim()
        if (!$enteredUrl -or $enteredUrl.TrimEnd('/') -ieq $localServerUrl) {
            [IO.File]::Delete($serverUrlSetting)
        } elseif (Test-RememberedServerUrl $enteredUrl) {
            [IO.File]::WriteAllText($serverUrlSetting, $enteredUrl)
        }
    } catch {
        Write-Warning "Could not save the J-PPI settings: $($_.Exception.Message)"
    }
})
$browse = Add-Control Button 'Browse...' 314 40 74 27 $true
$null = Add-Control Label 'Search by Song Title or Album Title' 16 78 372 22 $true
$search = Add-Control TextBox '' 16 101 372 24 $true
$results = Add-Control ListBox '' 16 138 372 309 $true
$results.HorizontalScrollbar = $true
$results.SelectionMode = 'MultiExtended'
$results.DisplayMember = 'Label'
$addResults = Add-Control Button 'Add selected tracks' 16 458 150 34 $true
$searchStatus = Add-Control Label '' 16 508 372 45 $true

$audioPattern = '\.(mp3|flac|m4a|aac|wav|ogg|opus|wma|aiff|aif|alac|ape|mka)$'
$searchState = @{
    Folder = $null
    Files = @()
    Indexed = $false
    Worker = $null
    Pending = $null
    Refresh = $true
}
$searchTimer = [Windows.Forms.Timer]::new()
$searchTimer.Interval = 250

function Show-SearchResults {
    $terms = [regex]::Matches($search.Text, '[\p{L}\p{M}\p{N}]+').Value
    $results.BeginUpdate()
    try {
        $results.Items.Clear()
        if (!$terms) {
            $searchStatus.Text = "$($searchState.Files.Count) audio files indexed. Type to search."
            return
        }
        $matchesFound = 0
        foreach ($file in $searchState.Files) {
            $containsAllTerms = $true
            foreach ($term in $terms) {
                if ($file.Path.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
                    $containsAllTerms = $false
                    break
                }
            }
            if (!$containsAllTerms) { continue }
            $matchesFound++
            if ($matchesFound -le 500) { $null = $results.Items.Add($file) }
        }
        $searchStatus.Text = if ($matchesFound -gt 500) {
            "Showing 500 of $matchesFound matches. Refine your search to see fewer results."
        } else { "$matchesFound match(es)." }
    }
    finally { $results.EndUpdate() }
}

$searchTimer.Add_Tick({
    $folder = $searchPath.Text.Trim()
    if ($folder -cne $searchState.Folder) {
        if ($searchState.Worker) {
            $searchState.Worker.Stop()
            $searchState.Worker.Dispose()
            $searchState.Worker = $null
        }
        $searchState.Folder = $folder
        $searchState.Files = @()
        $searchState.Indexed = $false
        $results.Items.Clear()
        if (!$folder) {
            $searchStatus.Text = 'Choose a search folder.'
            return
        }

        $worker = [powershell]::Create()
        $null = $worker.AddScript({
            param($folder, $audioPattern)
            $root = Get-Item -LiteralPath $folder -ErrorAction Stop
            if ($root -isnot [IO.DirectoryInfo]) { throw 'Choose a folder to search.' }
            $prefix = $root.FullName.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
            Get-ChildItem -LiteralPath $root.FullName -Recurse -File -ErrorAction Stop |
                Where-Object { $_.Extension -match $audioPattern } |
                ForEach-Object {
                    [pscustomobject]@{ Label = $_.FullName.Substring($prefix.Length); Path = $_.FullName }
                }
        }).AddArgument($folder).AddArgument($audioPattern)
        $searchState.Worker = $worker
        $searchState.Pending = $worker.BeginInvoke()
        $searchStatus.Text = 'Indexing audio files...'
    }

    if ($searchState.Worker) {
        if (!$searchState.Pending.IsCompleted) { return }
        try {
            $searchState.Files = @($searchState.Worker.EndInvoke($searchState.Pending))
            $searchState.Indexed = $true
            $searchState.Refresh = $true
        }
        catch {
            $searchStatus.Text = "Could not search folder. $($_.Exception.GetBaseException().Message)"
            $searchState.Refresh = $false
        }
        finally {
            $searchState.Worker.Dispose()
            $searchState.Worker = $null
        }
    }

    if ($searchState.Refresh -and $folder -and $searchState.Files.Count -gt 0) {
        $searchState.Refresh = $false
        Show-SearchResults
    } elseif ($searchState.Refresh -and $folder) {
        $searchState.Refresh = $false
        $searchStatus.Text = 'No audio files found in this folder.'
    }
})
$search.Add_TextChanged({
    if ($searchState.Files.Count -gt 0) { $searchState.Refresh = $true }
})
$browse.Add_Click({
    $picker = [Windows.Forms.FolderBrowserDialog]::new()
    try {
        $picker.SelectedPath = $searchPath.Text
        if ($picker.ShowDialog($form) -eq 'OK') { $searchPath.Text = $picker.SelectedPath }
    }
    finally { $picker.Dispose() }
})

function Add-SearchSelection {
    if ($searchPath.Text.Trim() -cne $searchState.Folder) { return }
    foreach ($file in $results.SelectedItems) { $null = $tracks.Items.Add($file.Path) }
    $status.Text = "$($tracks.Items.Count) track(s) selected."
}
$addResults.Add_Click({ Add-SearchSelection })
$results.Add_DoubleClick({ Add-SearchSelection })

function Update-MissingTracks {
    $missingTracks.Clear()
    $missingCount = 0
    foreach ($path in $tracks.Items) {
        if (![IO.File]::Exists($path)) {
            $null = $missingTracks.Add($path)
            $missingCount++
        }
    }
    $repair.Visible = $missingCount -gt 0
    $offset = if ($missingCount -gt 0) { $repair.Width + 8 } else { 0 }
    for ($buttonIndex = 0; $buttonIndex -lt $trackButtons.Count; $buttonIndex++) {
        $trackButtons[$buttonIndex].Left = $trackButtonPositions[$buttonIndex] + $offset
    }
    $tracks.Invalidate()
    $missingCount
}

function Get-TrackSearchTitle([string] $path) {
    $title = [IO.Path]::GetFileNameWithoutExtension($path) -replace '^\s*(?:\d{1,2}[-.]\d{1,3}|\d{1,3})[\s._-]+', ''
    ($title -replace '[^\p{L}\p{M}\p{N}]+', ' ').Trim()
}

function Show-MissingTrackDialog([string] $path, [object[]] $candidates) {
    $dialog = [Windows.Forms.Form]::new()
    try {
        Set-AppWindowIdentity $dialog
        $dialog.ClientSize = [Drawing.Size]::new(760, 350)
        $dialog.StartPosition = 'CenterParent'
        $dialog.FormBorderStyle = 'FixedSingle'
        $dialog.MaximizeBox = $false
        $dialog.MinimizeBox = $false

        $message = [Windows.Forms.Label]::new()
        $message.SetBounds(12, 12, 736, 66)
        $message.Text = if ($candidates.Count) {
            "Select a replacement for:`r`n$path"
        } else {
            "No matches in the indexed folder for:`r`n$path"
        }
        $dialog.Controls.Add($message)

        $choices = [Windows.Forms.ListBox]::new()
        $choices.SetBounds(12, 84, 736, 204)
        $choices.HorizontalScrollbar = $true
        $choices.DisplayMember = 'Path'
        $choices.Items.AddRange($candidates)
        $dialog.Controls.Add($choices)

        $replace = [Windows.Forms.Button]::new()
        $replace.Text = 'Replace selected'
        $replace.SetBounds(12, 303, 130, 32)
        $replace.DialogResult = 'OK'
        $replace.Enabled = $false
        $choices.Add_SelectedIndexChanged({ $replace.Enabled = $choices.SelectedIndex -ge 0 })
        $dialog.Controls.Add($replace)

        $removeFile = [Windows.Forms.Button]::new()
        $removeFile.Text = 'Remove from playlist'
        $removeFile.SetBounds(151, 303, 145, 32)
        $removeFile.DialogResult = 'Abort'
        $dialog.Controls.Add($removeFile)

        $skip = [Windows.Forms.Button]::new()
        $skip.Text = 'Skip file'
        $skip.SetBounds(305, 303, 100, 32)
        $skip.DialogResult = 'Ignore'
        $dialog.Controls.Add($skip)

        switch ($dialog.ShowDialog($form)) {
            OK { @{ Action = 'Replace'; Path = $choices.SelectedItem.Path } }
            Abort { @{ Action = 'Remove' } }
            Ignore { @{ Action = 'Skip' } }
            default { @{ Action = 'Stop' } }
        }
    }
    finally { $dialog.Dispose() }
}

$repair.Add_Click({
    if ($searchState.Worker -or $searchPath.Text.Trim() -cne $searchState.Folder -or !$searchState.Indexed) {
        $status.Text = 'Choose a searchable folder on the left and wait for indexing to finish.'
        return
    }

    $indexedTracks = @(foreach ($file in $searchState.Files) {
        [pscustomobject]@{ Path = $file.Path; Title = Get-TrackSearchTitle $file.Path }
    })
    for ($index = 0; $index -lt $tracks.Items.Count; $index++) {
        $path = [string] $tracks.Items[$index]
        if (!$missingTracks.Contains($path) -or [IO.File]::Exists($path)) { continue }

        $title = Get-TrackSearchTitle $path
        $candidates = @(if ($title) {
            $indexedTracks | Where-Object {
                $_.Title.IndexOf($title, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and [IO.File]::Exists($_.Path)
            } | Sort-Object @{ Expression = { $_.Title -ine $title } }, Path
        })
        $tracks.SelectedIndex = $index
        $decision = Show-MissingTrackDialog $path $candidates
        if ($decision.Action -eq 'Stop') { break }
        if ($decision.Action -eq 'Replace') { $tracks.Items[$index] = $decision.Path }
        if ($decision.Action -eq 'Remove') {
            $tracks.Items.RemoveAt($index)
            $index--
        }
    }
    $remaining = Update-MissingTracks
    $status.Text = "$remaining missing track(s) remaining."
})

function Read-PlaylistTracks([string] $playlistPath) {
    $folder = [IO.Path]::GetDirectoryName($playlistPath)
    foreach ($line in [IO.File]::ReadLines($playlistPath)) {
        $entry = $line.Trim()
        if (!$entry -or $entry.StartsWith('#')) { continue }

        if ($entry -match '^file://') {
            $entry = ([uri] $entry).LocalPath
        } elseif ($entry -match '^[a-z][a-z0-9+.-]*://') {
            throw 'This playlist contains a stream URL. Open a playlist of local audio files.'
        }

        [IO.Path]::GetFullPath([IO.Path]::Combine($folder, $entry))
    }
}

$open.Add_Click({
    $picker = [Windows.Forms.OpenFileDialog]::new()
    try {
        $picker.Title = 'Open a playlist'
        $picker.Filter = 'M3U playlists (*.m3u;*.m3u8)|*.m3u;*.m3u8'
        if ($picker.ShowDialog($form) -ne 'OK') { return }

        $entries = @(Read-PlaylistTracks $picker.FileName)
        if (!$entries.Count) {
            $status.Text = 'The selected playlist contains no tracks.'
            return
        }
        if ($tracks.Items.Count -gt 0) {
            $answer = [Windows.Forms.MessageBox]::Show($form, 'Replace the tracks currently in the editor?', 'Open playlist', 'YesNo', 'Question')
            if ($answer -ne 'Yes') { return }
        }

        $tracks.BeginUpdate()
        try {
            $tracks.Items.Clear()
            $tracks.Items.AddRange([string[]] $entries)
            $missingCount = Update-MissingTracks
        }
        finally { $tracks.EndUpdate() }
        $foundCount = $entries.Count - $missingCount
        $status.Text = "Opened $([IO.Path]::GetFileName($picker.FileName)). $foundCount of $($entries.Count) tracks found. $missingCount missing."
    }
    catch {
        [Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'Could not open playlist', 'OK', 'Error') | Out-Null
    }
    finally { $picker.Dispose() }
})

$add.Add_Click({
    $picker = [Windows.Forms.OpenFileDialog]::new()
    try {
        $picker.Multiselect = $true
        $picker.Filter = 'Audio files|*.mp3;*.flac;*.m4a;*.aac;*.wav;*.ogg;*.opus;*.wma;*.aiff;*.aif;*.alac;*.ape;*.mka|All files|*.*'
        if ($picker.ShowDialog($form) -eq 'OK') {
            $tracks.Items.AddRange($picker.FileNames)
            $status.Text = "$($tracks.Items.Count) track(s) selected."
        }
    }
    finally { $picker.Dispose() }
})

$remove.Add_Click({
    if ($tracks.SelectedIndex -ge 0) {
        $tracks.Items.RemoveAt($tracks.SelectedIndex)
        $remaining = Update-MissingTracks
        $status.Text = "$($tracks.Items.Count) track(s). $remaining missing."
    }
})

function Move-Track([int] $offset) {
    $index = $tracks.SelectedIndex
    $destination = $index + $offset
    if ($index -ge 0 -and $destination -ge 0 -and $destination -lt $tracks.Items.Count) {
        $item = $tracks.Items[$index]
        $tracks.Items.RemoveAt($index)
        $tracks.Items.Insert($destination, $item)
        $tracks.SelectedIndex = $destination
    }
}
$up.Add_Click({ Move-Track -1 })
$down.Add_Click({ Move-Track 1 })

function Save-Playlist([bool] $sendToPlex) {
    if (!$tracks.Items.Count) {
        $status.Text = 'Add at least one audio file.'
        return
    }
    if ($sendToPlex -and $localPlexToken -and $token.Text.Trim() -ceq $localPlexToken -and
        $server.Text.Trim().TrimEnd('/') -ine $localServerUrl) {
        $status.Text = 'The local registry token can only be used with the default local server URL.'
        return
    }
    if ($sendToPlex -and [string]::IsNullOrWhiteSpace($token.Text) -and
        [string]::IsNullOrWhiteSpace($env:PLEX_TOKEN)) {
        $status.Text = 'Enter your Plex token to import.'
        $token.Focus() | Out-Null
        return
    }

    $destination = [Windows.Forms.SaveFileDialog]::new()
    try {
        $destination.Title = 'Name the playlist'
        $destination.Filter = 'M3U playlist (*.m3u)|*.m3u'
        $destination.DefaultExt = 'm3u'
        $destination.FileName = 'My Playlist.m3u'
        $destination.OverwritePrompt = $true
        if ($destination.ShowDialog($form) -ne 'OK') { return }
        $path = $destination.FileName
    }
    finally { $destination.Dispose() }

    $options = @{ TrackPath = [string[]] @($tracks.Items); OutputPath = $path }
    if ([IO.File]::Exists($path)) { $options.Overwrite = $true }
    $status.Text = 'Saving playlist...'
    if ($sendToPlex) {
        $options.Import = $true
        $options.Server = $server.Text.Trim()
        $options.LibraryName = $library.Text.Trim()
        if (![string]::IsNullOrWhiteSpace($token.Text)) {
            $options.PlexToken = ConvertTo-SecureString -String $token.Text.Trim() -AsPlainText -Force
        }
        $status.Text = 'Saving and importing playlist...'
    }

    $form.UseWaitCursor = $true
    $status.Refresh()
    try {
        & "$PSScriptRoot/New-PlexPlaylist.ps1" @options | ForEach-Object {
            $status.Text = $_
            $status.Refresh()
        }
    }
    catch {
        $status.Text = 'Operation failed. Check the error details.'
        [Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'Playlist error', 'OK', 'Error') | Out-Null
    }
    finally { $form.UseWaitCursor = $false }
}

$save.Add_Click({ Save-Playlist $false })
$import.Add_Click({ Save-Playlist $true })
function Show-StartupSplash {
    $imagePath = Join-Path $appDirectory 'J-PPI-splash.png'
    if (![IO.File]::Exists($imagePath)) { return }

    try { $image = [Drawing.Image]::FromFile($imagePath) }
    catch { return }

    $splash = [Windows.Forms.Form]::new()
    $bitmap = $null
    $outline = $null
    $timer = [Windows.Forms.Timer]::new()
    try {
        Set-AppWindowIdentity $splash
        $splash.ClientSize = [Drawing.Size]::new(480, 480)
        $splash.StartPosition = 'CenterScreen'
        $splash.FormBorderStyle = 'None'
        $splash.ShowInTaskbar = $false
        $splash.BackColor = [Drawing.Color]::FromArgb(18, 17, 24)

        $width = $splash.ClientSize.Width
        $height = $splash.ClientSize.Height
        $bitmap = [Drawing.Bitmap]::new($width, $height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.InterpolationMode = 'HighQualityBicubic'
            $graphics.DrawImage($image, 0, 0, $width, $height)
        }
        finally { $graphics.Dispose() }

        # Clip the rounded tile at its alpha boundary so the edge blends into the
        # splash's dark background instead of a chroma key.
        $outline = [Drawing.Drawing2D.GraphicsPath]::new()
        for ($y = 0; $y -lt $height; $y++) {
            $left = 0
            while ($left -lt $width -and $bitmap.GetPixel($left, $y).A -lt 128) { $left++ }
            if ($left -eq $width) { continue }
            $right = $width - 1
            while ($right -gt $left -and $bitmap.GetPixel($right, $y).A -lt 128) { $right-- }
            $outline.AddRectangle([Drawing.Rectangle]::new($left, $y, ($right - $left + 1), 1))
        }
        $splash.Region = [Drawing.Region]::new($outline)

        $picture = [Windows.Forms.PictureBox]::new()
        $picture.Image = $bitmap
        $picture.SizeMode = 'Normal'
        $picture.Dock = 'Fill'
        $splash.Controls.Add($picture)
        $picture.Add_Click({ $splash.Close() })

        $timer.Interval = 1000
        $timer.Add_Tick({ $timer.Stop(); $splash.Close() })
        $splash.Add_Shown({ $timer.Start() })
        $splash.ShowDialog() | Out-Null
    }
    finally {
        $timer.Dispose()
        $splash.Dispose()
        if ($outline) { $outline.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
        $image.Dispose()
    }
}

try {
    Show-StartupSplash
    $libraryTimer.Start()
    $searchTimer.Start()
    $form.ShowDialog() | Out-Null
}
finally {
    $searchTimer.Dispose()
    $libraryTimer.Dispose()
    if ($libraryState.Worker) { $libraryState.Worker.Dispose() }
    if ($searchState.Worker) { $searchState.Worker.Dispose() }
    $form.Dispose()
}
