<#
    .SYNOPSIS
    This is the main script of the project "Hello my Dir!".

    .COMPONENT
    PowerShell v5 minimum.

    .DESCRIPTION
    This is the main script to execute the project "Hello my Dir!". This project is intended to ease in building a secure active directory from scratch and maintain it afteward.

    .EXAMPLE
    .\HelloMyDir.ps1 -Prepare
    Will only query for setup data (generate the RunSetup.xml file). 

    .EXAMPLE
    .\HelloMyDir.ps1
    Will run the script for installation purpose (or failed if not RunSetup.xml is present). 

    .NOTES
    Version.: 01.00.000
    Author..: Loic VEIRMAN (MSSec)
    History.: 
    01.00.000   Script creation.
#>
Param(
    [Parameter(Position=0)]
    [switch]
    $Prepare
)

# Load modules. If a module fails on load, the script will stop.
Try {
    Import-Module -Name (Get-ChildItem .\Modules) -ErrorAction Stop | Out-Null
}
Catch {
    Write-Error "Failed to load modules."
    Exit 1
}

# Initiate logging
$DbgLog = @('START: invoke-HelloMyDir')
Test-EventLog
if ($Prepare) {
    $DbgLog += 'Option "Prepare" declared: the file RunSetup.xml will be generated'
} 
else {
    $DbgLog += 'No option used: the setup will perform action to configure your AD.'
}
Write-toEventLog -EventType INFO -EventMsg $DbgLog
$DbgLog = $null

# USE CASE 1: PREPARE XML SETUP FILE
if ($Prepare) {
    # Test if a configuration file already exists - if so, we will use it.
    $DbgLog = @('PHASE INIT: TEST IF A PREVIOUS RUN IS DETECTED.')
    if (Test-Path .\Configuration\RunSetup.xml) {
        # A file is present. We will rename it to a previous version to read old values and offers them as default option.
        $DbgLog += 'The file ".\Configuration\RunSetup.xml" is present, it will be converted to the last backup file.'
        if (Test-Path .\Configuration\RunSetup.last) {
            $DbgLog += 'As a file named ".\Configuration\RunSetup.last" is already present, this file will overwrite the existing one.'
            Remove-Item -Path .\Configuration\RunSetup.last -Force | Out-Null
            Rename-item -Path .\Configuration\RunSetup.xml -NewName .\Configuration\RunSetup.last -ErrorAction SilentlyContinue
            
            # Loading .last file as default option for the script.
            $DbgLog += 'As a file named ".\Configuration\RunSetup.last" is already present, this file will overwrite the existing one.'
            $DefaultChoices = Get-XmlContent .\Configuration\RunSetup.last -ErrorAction SilentlyContinue
        }
        Else {
            $DbgLog += 'No previous run detected.'
        }
    }
    Write-toEventLog INFO $DbgLog
    $DbgLog = $null

    # Preload previous run options
    $DbgLog = @('XML BUILDERS: PRELOAD ANSWERS FROM PREVIOUS RUN.')
    if (Test-Path .\Configuration\RunSetup.last) {
        Try {
            $lastRunOptions = Get-XmlContent -XmlFile .\Configuration\RunSetup.last -ErrorAction Stop
            $DbgLog += @('Variable: $LastRunOptions','Loaded with .\Configuration\RunSetup.last xml data.')
            Write-toEventLog INFO $DbgLog
        }
        Catch {
            $lastRunOptions = $null
            $DbgLog += @('Variable: $LastRunOptions','Failed to be loaded with .\Configuration\RunSetup.last xml data.')
            Write-toEventLog WARNING $DbgLog
        }
    }
    $DbgLog = $null

    # Create XML settings file
    $DbgLog = @('XML BUILDERS: CREATE XML SETUP FILE')
    $RunSetup = New-XmlContent -XmlFile (.\Configuration\RunSetup.xml)
    
    if ($RunSetup) {
        $DbgLog += @("File .\Configuration\RunSetup.xml created.","The file will now be filled with user's choices.")
        $RunSetup.WriteStartElement('HmDSetup')
        Write-toEventLog INFO $DbgLog
        $DbgLog = $null
    }
    Else {
        $DbgLog += @("FATAL ERROR: the file .\Configuration\RunSetup.xml could not be created.","The script will end with error code 2.")
        Write-toEventLog ERROR $DbgLog
        Write-Error "ERROR: THE CONFIGURATION FILE COULD NOT BE CREATED."
        Exit 2
    }

    # Inquiring for setup data: the forest.
    $DbgLog = @("SETUP DATA COLLECT: FOREST"," ")

    # # Forest FFL
    $ProposedAnswer = $DefaultChoices.HmDSetup.Forest.FunctionalLevel

    # # Forest DFL
    $ProposedAnswer = $DefaultChoices.HmDSetup.Forest.Domain.FunctionalLevel

    # # Forest Root domain SafeMode Admin Pwd
    $ProposedAnswer = New-RandomComplexPasword -Length 24

    # # Forest Root Domain Fullname
    $ProposedAnswer = $DefaultChoices.HmDSetup.Forest.Domain.Name

    # # Forest Root Domain NetBIOS
    $ProposedAnswer = $DefaultChoices.HmDSetup.Forest.Domain.NetBIOS

    # # Forest Database path
    $ProposedAnswer = $DefaultChoices.HmDSetup.Forest.Domain.Path.NTDS

    # # Forest Sysvol path
    $ProposedAnswer = $DefaultChoices.HmDSetup.Forest.Domain.Path.SysVol

    # # Forest Optional Attributes: Recycle Bin
    $ProposedAnswer = $DefaultChoices.HmDSetup.Forest.ADRecycleBin

    # # Forest Optional Attributes: Privileged Access Management
    $ProposedAnswer = $DefaultChoices.HmDSetup.Forest.ADPAM

}
# USE CASE 2: SETUP AD
Else {

}

# Unolad modules
Remove-Module -Name (Get-ChildItem .\Modules).Name -ErrorAction SilentlyContinue | Out-Null

# Exit
Write-toEventLog -EventType INFO -EventMsg "END: invoke-HelloMyDir"
Exit 0