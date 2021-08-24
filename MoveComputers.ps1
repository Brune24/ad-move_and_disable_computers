##########################################
# Date de création: 04/03/21             #
# Date de modification: 26/03/21         #
# Auteur: PSAULIERE                      #
##########################################

<#

.SYNOPSIS
Read computers from a file & move them to a specific OU

.DESCRIPTION
* Read Input File from a path & store content into an array
* Move Objects from array to an OU
* Log success & error exception messsages
* Move input file to .old directory & add date
* Move log file to .old directory & add date
* TODO Logrotate logfile
* (Might be better to have target OU & input file as parameters)

.EXAMPLE
N/A

.NOTES
N/A

.LINK
N/A

#>

Import-module ActiveDirectory

Function ReadFile{
    $script:Computers = @(Get-Content -Path $InputFile)
    If (Test-Path $InputFile){
        If ($Computers -ne $null){
            WriteLog -Message "Read Hosts file: OK"    
        }
        else{
            WriteLog -Message "Read Hosts file: EMPTY" -Severity Error
            MoveFile
            Exit
        }        
    }      
    Else{
        WriteLog -Message "Read Hosts file: NONE" -Severity Error
        WriteLog -Message "Read Hosts file: $Error[0].Exception.Message" -Severity Error
        MoveFile
        Exit        
    }
}

Function MoveComputer{
    ForEach ($Computer in $Computers) {
        $DN = Get-ADComputer -Filter 'Name -like $Computer' | Select-Object -ExpandProperty DistinguishedName
        If ($DN -eq $null){
            WriteLog -Message "MoveComputer: $Computer Not found"
        }
        Else {
            WriteLog -Message "MoveComputer: $Computer $DN"
        }

        Get-ADComputer -Identity $Computer | Move-ADObject -TargetPath "$TargetOU" -Verbose
        Set-ADComputer -Identity $Computer -Enabled $False
        If (!$?){
            WriteLog -Message "MoveComputer: $Computer $Error[0].Exception.Message" -Severity Error
        }
    }
}

Function MoveFile{
    ${Date} = Get-Date -UFormat "%Y-%m-%d %Hh%Mm%Ss"
    mv -Path $InputFile -Destination $TargetPath\$Date-hosts.txt   
    If(Test-Path $TargetPath\$Date-hosts.txt){
        WriteLog -Message "MoveFile: Move InputFile OK"
    }
    Else{
        WriteLOg -Message "MoveFile: Move InputFile NOK" -Severity Error
    }

    mv -Path $LogFile -Destination $TargetPath\$Date-log.log   
}


Function WriteLog{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [String]$Severity = 'Information'
        )
    [pscustomobject]@{
    Time = (Get-Date -UFormat '%y-%m-%d %H:%M:%S')
    Message = $Message
    Severity = $Severity
    } | Out-File $LogFile -Append
}


Function Test{}

Function Main{
    $script:InputFile = "$env:HOMEPATH\scripts\hosts.*"
    $script:LogFile = "$env:HOMEPATH\scripts\log.log"
    $script:TargetPath = "$env:HOMEPATH\scripts\old"
    $script:TargetOu = ''
    
    if (!(Test-path $LogFile)){
        New-Item -Path $LogFile
    }
    
    #Test
    ReadFile
    MoveComputer
    MoveFile
}

Main