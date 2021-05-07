﻿<#
.SYNTAX       build-repo.ps1 [<repo-dir>]
.DESCRIPTION  builds a Git repository (supporting cmake,configure,autogen,Imakefile,Makefile)
.LINK         https://github.com/fleschutz/PowerShell
.NOTES        Author: Markus Fleschutz / License: CC0
#>

param($RepoDir = "$PWD")

function MakeDir { param($Path)
	$DirName = (get-item "$Path").Name
	if (test-path "$Path/CMakeLists.txt") {
		"⏳ Building 📂$DirName using CMakeLists.txt ..."
		if (-not(test-path "$Path/BuildFiles/" -pathType container)) { 
			& mkdir "$Path/BuildFiles/"
		}

		set-location "$Path/BuildFiles/"
		& cmake ..
		if ($lastExitCode -ne "0") { throw "Executing 'cmake ..' has failed" }

		& make -j4
		if ($lastExitCode -ne "0") { throw "Executing 'make -j4' has failed" }

		set-location ..

	} elseif (test-path "$Path/configure") { 
		"⏳ Building 📂$DirName using 'configure' ..."
		set-location "$Path/"

		& ./configure
		if ($lastExitCode -ne "0") { throw "Executing 'configure' has failed" }

		& make -j4
		if ($lastExitCode -ne "0") { throw "Executing 'make -j4' has failed" }

	} elseif (test-path "$Path/autogen.sh") { 
		"⏳ Building 📂$DirName using 'autogen.sh' ..."
		set-location "$Path/"

		& ./autogen.sh
		if ($lastExitCode -ne "0") { throw "Script 'autogen.sh' has failed" }

		& make -j4
		if ($lastExitCode -ne "0") { throw "Executing 'make -j4' has failed" }

	} elseif (test-path "$Path/Imakefile") {
		"⏳ Building 📂$DirName using Imakefile ..."
		set-location "$RepoDir/"

		& xmkmf 
		if ($lastExitCode -ne "0") { throw "Executing 'xmkmf' has failed" }

		& make -j4
		if ($lastExitCode -ne "0") { throw "Executing 'make -j4' has failed" }

	} elseif (test-path "$Path/Makefile") {
		"⏳ Building 📂$DirName using Makefile..."
		set-location "$Path"

		& make -j4
		if ($lastExitCode -ne "0") { throw "Executing 'make -j4' has failed" }

	} elseif (test-path "$Path/attower/src/build/DevBuild/build.bat") {
		"⏳ Building 📂$DirName using build.bat ..."
		set-location "$Path/attower/src/build/DevBuild/"

		& ./build.bat build-all-release
		if ($lastExitCode -ne "0") { throw "Script 'build.bat' returned error(s)" }

	} elseif (test-path "$Path/$DirName" -pathType container) {
		"⏳ No make rule found, but trying the subdirectory 📂$DirName ..."
		MakeDir "$Path/$DirName"
	} else {
		write-warning "Sorry, no make rule found in 📂$DirName"
		exit 0
	}
}

try {
	$StopWatch = [system.diagnostics.stopwatch]::startNew()

	if (-not(test-path "$RepoDir" -pathType container)) { throw "Can't access directory: $RepoDir" }
	$RepoDirName = (get-item "$RepoDir").Name

	MakeDir "$RepoDir"

	[int]$Elapsed = $StopWatch.Elapsed.TotalSeconds
	"✔️ built Git repository 📂$RepoDirName in $Elapsed sec."
	exit 0
} catch {
	write-error "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
