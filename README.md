# J-PPI

Jabe's Plex Playlist Importer builds and edits local music playlists, finds replacements for missing tracks, and imports M3U playlists into Plex Media Server for playback in Plexamp.

## Run on Windows

Run **J-PPI-Windows-Setup.exe**, choose your shortcuts, and open **J-PPI** from Start or the desktop. To uninstall, use **Settings > Apps > Installed apps**. The Windows ZIP is a portable alternative and starts from **J-PPI.cmd**.

1. Choose a music folder and type a search query. Search terms can match different parts of a file's path.
2. Add tracks from the search results or open an existing M3U. Missing tracks are highlighted and can be repaired using the indexed folder.
3. Select **Save .m3u** to write the playlist, or select **Save and import** to send it to Plex after saving.

## Connect to Plex

Enter your Plex Media Server URL. The default is `http://localhost:32400`. The app can read the server token from the current Windows user's Plex registry settings for the default local URL. You can also enter the token for the Plex account you use in Plexamp. The app lists music libraries available to that account.

The server imports the saved playlist from an absolute path. Save it where the server can read that path, and use track paths that match files already indexed in the selected music library. If the app and Plex server use different paths for the same files, the current version requires a shared path that both can use.

Keep Plex tokens, personal playlists, and track lists out of commits.

## Release notes and updates

Open **Help > User Guide** for instructions or **Help > About J-PPI** for the installed version, release notes, and GitHub updates. The installed app checks the official J-PPI GitHub repository. A source checkout can use its GitHub `origin` remote, or you can override the repository with `JPPI_GITHUB_REPO` in `owner/repository` format. Publish stable releases with tags such as `v0.1.0`. For a newer release, **Update** opens its GitHub release page.

## Cross-platform desktop port

The Windows PowerShell app is the current runnable version. The planned desktop port uses C# and Avalonia for Windows and Linux. It will carry over playlist editing, live search, missing-file repair, and Plex library selection. The port also needs explicit handling for differing client and server paths, plus Windows and Linux package builds.

## License

J-PPI is available under the [MIT License](LICENSE).
