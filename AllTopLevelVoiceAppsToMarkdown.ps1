<#
    .SYNOPSIS
    Used the M365 Call Flow Visualizer Script to create a seperate Markdown file for each top level voice app and creates a Markdown file which includes all the other markdown files.

    .DESCRIPTION
    Searches for auto attendants and call queues which have at least one phone number assigned. It then runs the M365 Call flow visualizer for each top level voice app. A seperate Markdown file is created for each call flow. Each call flow Markdown file is added to a
    single Markdown file so that all call flows can be rendered on one page.

    Author:             Martin Heusser
    Version:            1.0.2
    Revision:
        05.01.2022      1.0.0: Creation
        12.01.2022      1.0.1: Migrate from MSOnline to Microsoft.Graph
        08.04.2022      1.0.2: Move Connect-M365CFV function to sepearate file, default output folder set to .\Output

#>

#Requires -Modules @{ ModuleName = "MicrosoftTeams"; ModuleVersion = "4.6.0" }, "Microsoft.Graph.Users", "Microsoft.Graph.Groups"

. .\Functions\Connect-M365CFV.ps1

. Connect-M365CFV

$VoiceApps = @()

$AllAutoAttendants = Get-CsAutoAttendant -First 1000 | Where-Object {$_.ApplicationInstances -notlike ""}

$AllCallQueues = Get-CsCallQueue -First 1000 -WarningAction SilentlyContinue | Where-Object {$_.ApplicationInstances -notlike ""}

foreach ($AutoAttendant in $AllAutoAttendants) {

    $ResourceAccounts = $AutoAttendant.ApplicationInstances

    foreach ($ResourceAccount in $ResourceAccounts) {

        $ResourceAccountCheck = Get-CsOnlineApplicationInstance -Identity $ResourceAccount

        if ($ResourceAccountCheck.PhoneNumber) {

            $VoiceApps += $AutoAttendant.Identity

        }

    }
    
}

foreach ($CallQueue in $AllCallQueues) {

    $ResourceAccounts = $CallQueue.ApplicationInstances

    foreach ($ResourceAccount in $ResourceAccounts) {

        $ResourceAccountCheck = Get-CsOnlineApplicationInstance -Identity $ResourceAccount

        if ($ResourceAccountCheck.PhoneNumber) {

            $VoiceApps += $CallQueue.Identity

        }

    }
    
}

if (!(Test-Path -Path .\Output)) {

    New-Item -Path .\Output -ItemType Directory

}

Set-Content -Path ".\Output\TopLevelVoiceApps.md" -Value "# Call Flow Diagrams"

foreach ($VoiceAppIdentity in $VoiceApps) {

    . .\M365CallFlowVisualizerV2.ps1 -Identity $VoiceAppIdentity -Theme dark -CustomFilePath ".\Output" -ShowCqAgentPhoneNumbers -ExportAudioFiles -ExportTTSGreetings -ShowAudioFileName -ShowTTSGreetingText -ExportPng $true

    $MarkdownInclude = "[!include[$($VoiceAppFileName)]($(($VoiceAppFileName).Replace(" ","_"))_CallFlow$fileExtension)]"

    Add-Content -Path ".\Output\TopLevelVoiceApps.md" -Value $MarkdownInclude

}
