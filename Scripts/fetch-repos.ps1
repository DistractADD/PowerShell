﻿<#
.SYNTAX       fetch-repos.ps1 [<parent-dir>]
.DESCRIPTION  fetches updates for all Git repositories under the current/given directory (including submodules)
.LINK         https://github.com/fleschutz/PowerShell
.NOTES        Author: Markus Fleschutz / License: CC0
#>

param($ParentDir = "$PWD")

try {
	$StopWatch = [system.diagnostics.stopwatch]::startNew()

	if (-not(test-path "$ParentDir" -pathType container)) { throw "Can't access directory: $ParentDir" }

	$Null = (git --version)
	if ($lastExitCode -ne "0") { throw "Can't execute 'git' - make sure Git is installed and available" }

	$Folders = (get-childItem "$ParentDir" -attributes Directory)
	$FolderCount = $Folders.Count
	$ParentDirName = (get-item "$ParentDir").Name
	"Fetching updates for $FolderCount Git repositories at 📂$ParentDirName..."

	foreach ($Folder in $Folders) {
		$FolderName = (get-item "$Folder").Name
		"🢃 Fetching 📂$FolderName..."

		& git -C "$Folder" fetch --all --recurse-submodules --jobs=4
		if ($lastExitCode -ne "0") { throw "'git fetch' failed" }
	}

	[int]$Elapsed = $StopWatch.Elapsed.TotalSeconds
	"✔️ fetched $FolderCount Git repositories at 📂$ParentDirName in $Elapsed sec"
	exit 0
} catch {
	write-error "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
