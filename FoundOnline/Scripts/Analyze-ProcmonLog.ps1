﻿<#
.Synopsis
   Script to parse Process Monitor XML log file, and give you a summary report.
   The report conaints sections dedicated to Processes Created, File Activity, Registry Activity, Network Traffic, and Unique Hosts
   Autor: Moti Bani, contact: Moti.Bani@Microsoft.com   
.DESCRIPTION
   Instructions to prepare the Process Monitor trace this script requires:
   Start Procmon. 
   Stop the Procmon trace.
   Add an Include filter for "Result is SUCCESS".
    Save the trace:
    * Events displayed using current filter
    * DO NOT SELECT Also include profiling events
    * Format XML - do not check the stack traces or stack symbols options
.EXAMPLE
   .\Analyze-ProcmonLog.ps1 .\Logfile.XML 

 LEGAL DISCLAIMER 
    This Sample Code is provided for the purpose of illustration only and is not 
    intended to be used in a production environment.  THIS SAMPLE CODE AND ANY 
    RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER 
    EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF 
    MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a 
    nonexclusive, royalty-free right to use and modify the Sample Code and to 
    reproduce and distribute the object code form of the Sample Code, provided 
    that You agree: (i) to not use Our name, logo, or trademarks to market Your 
    software product in which the Sample Code is embedded; (ii) to include a valid 
    copyright notice on Your software product in which the Sample Code is embedded; 
    and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and 
    against any claims or lawsuits, including attorneys’ fees, that arise or result 
    from the use or distribution of the Sample Code. 
  
    This posting is provided "AS IS" with no warranties, and confers no rights. Use 
    of included script samples are subject to the terms specified 
    at http://www.microsoft.com/info/cpyright.htm. 
#>


#  ----------------------------------------------------------------------
#  Helper functions 
#  ----------------------------------------------------------------------

# Remove invalid characters and normalize the path
Function NormalizeFileName ([string]$rawPath)
{
    $rawPath = $rawPath.Replace("\??\",'')

    $invalidChars = [IO.Path]::GetInvalidPathChars() -join ''
    $EscapeChars = "[{0}]" -f [RegEx]::Escape($invalidChars)
    return ($rawPath -replace $EscapeChars)        
}

# Split the executable name from the arguments
Function SplitCommandLine([string]$rawCommandLine)
{
    if($rawCommandLine -match [RegEx]'(?i)([a-z]):.(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*\.\w{3}')
    {
        $Matches[0] 
    }
    # non-standard command line, try to split 
    else
    {
        $rawCommandLine.Split()[0]
    }
}

Function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
}

#simple output of the report to console
Function ConsoleWrite()
{
    if($ProcessesActivity.Count -gt 0)
    {
        Write-Host "Processes Created:" 
        Write-Host "==================" -NoNewline
        $ProcessesActivity | Format-Table @{n='Time';e={'{0}' -f $_.Time.ToShortTimeString()}},@{n='Parent Process';e={'{0} ({1})' -f $_.ParentProcessName, $_.ParentProcessPID}},@{n='Process';e={'{0} ({1})' -f $_.ChildProcessName, $_.ChildProcessPID}} -AutoSize
    }

    if ($FilesCreatedList.count -gt 0)
    {
        Write-Host "Files Created:" 
        Write-Host "==================" -NoNewline
        $FilesCreatedList  | Format-Table @{n='Time';e={'{0}' -f $_.Time.ToShortTimeString()}},@{n='Process';e={'{0}' -f $_.ProcessName}},@{n='Path';e={'{0}' -f $_.Path }} 
    }
   
    if ($FilesRenamedList.count -gt 0)
    {
        Write-Host "Files Renamed:" 
        Write-Host "==================" -NoNewline
        $FilesRenamedList | Format-Table @{n='Time';e={'{0}' -f $_.Time.ToShortTimeString()}},@{n='Process';e={'{0}' -f $_.ProcessName}},@{n='Path';e={'{0}' -f $_.Path }} 
    }

    if ($FileDeletedList.count -gt 0)
    {
        Write-Host "Files Deleted:" 
        Write-Host "==================" -NoNewline
        $FileDeletedList | Format-Table @{n='Time';e={'{0}' -f $_.Time.ToShortTimeString()}},@{n='Process';e={'{0}' -f $_.ProcessName}},@{n='Path';e={'{0}' -f $_.Path }} 
    }

   
    if ($RegCreateKeysList.count -gt 0)
    {
        Write-Host "Registry Created:" 
        Write-Host "==================" -NoNewline
        $RegCreateKeysList | Format-Table @{n='Time';e={'{0}' -f $_.Time.ToShortTimeString()}},@{n='Process';e={'{0}' -f $_.ProcessName}},@{n='Path';e={'{0}' -f $_.Path }} 
    }

    if ($RegSetValuesList.count -gt 0)
    {
        Write-Host "Registry Writes:" 
        Write-Host "==================" -NoNewline
        $RegSetValuesList | Sort-Object -Property Path, Value -Unique | Format-Table @{n='Time';e={'{0}' -f $_.Time.ToShortTimeString()}},@{n='Process';e={'{0}' -f $_.ProcessName}},@{n='Path';e={'{0}={1}' -f $_.Path, $_.Value}} 
    }

    if ($RegDeleteValuesList.count -gt 0)
    {
        Write-Host "Registry Deletes:" 
        Write-Host "==================" -NoNewline
        $RegDeleteValuesList | Format-Table @{n='Time';e={'{0}' -f $_.Time.ToShortTimeString()}},@{n='Process';e={'{0}' -f $_.ProcessName}},@{n='Path';e={'{0}' -f $_.Path}} 
    }

    if ($NetworkTraffic.count -gt 0)
    {
        Write-Host "Network Traffic:" 
        Write-Host "==================" -NoNewline
        $NetworkTraffic | Format-Table @{n='Time';e={'{0}' -f $_.Time.ToShortTimeString()}},@{n='Protocol';e={'{0}' -f $_.Protocol}},@{n='Process';e={'{0}' -f $_.ProcessName}},@{n='Path';e={'{0}' -f $_.Path}} 
    }

    if ($RemoteServers.count -gt 0)
    {
        Write-Host "Unique Hosts:" 
        Write-Host "==================" 
        $RemoteServers | Select-Object -Unique 
    }   
}

function Analyze-ProcmonLog
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Specifies the name of the input Procmon XML file.
        [parameter(Mandatory=$true)]
        [String]
        $ProcmonXmlFile
    )

    #  ----------------------------------------------------------------------
    #  Collections
    #  ----------------------------------------------------------------------

    $ProcessesActivity = @()
    $FilesCreatedList = @()
    $FilesRenamedList = @()
    $FileDeletedList = @()
    $RegCreateKeysList = @()
    $RegDeleteValuesList = @()
    $RegSetValuesList = @()
    $NetworkTraffic = @()
    $RemoteServers = @()
    $ProcessesArray = @()

    #  ----------------------------------------------------------------------
    #  Filters
    #  ----------------------------------------------------------------------

    # remove noisy Windows' processes, set UseFilteredProcesses to $false to include all process names
    $FilteredProcesses = @('SearchProtocolHost.exe', 'ngen.exe','SearchFilterHost.exe','wmiadap.exe','DllHost.exe','SearchIndexer.exe')
    $UseFilteredProcesses = $true


    # Build the list of events    
    $inputFile = [xml](Get-Content $ProcmonXmlFile)
    $Events = $inputFile.procmon.eventlist.event   

    # Main loop
    Foreach($Event in $Events) {
        switch ($Event.Operation) 
       {
           "Process Create" { 
           $currentPID = $Event.Detail.Substring(5,$Event.Detail.IndexOf(",")-5) 
           $currentCommandLine = $Event.Detail.Substring($Event.Detail.IndexOf(",")+16) 
           $ParentPID = $Event.PID
           $ParentCommandLine = NormalizeFileName(SplitCommandLine($Event.Process_Name))
           $EXE = NormalizeFileName(SplitCommandLine $currentCommandLine)
           $CreateTime = [DateTime]$Event.Time_of_Day
           if($UseFilteredProcesses)
            {
                if($FilteredProcesses -notcontains [System.IO.Path]::GetFileName($EXE))
                {
                    $obj = new-object psobject -Property @{
                                                            Time = $CreateTime
                                                            ChildProcessName = $currentCommandLine#[System.IO.Path]::GetFileName($EXE)
                                                            ChildProcessPID = $currentPID
                                                            ParentProcessName = $ParentCommandLine
                                                            ParentProcessPID = $ParentPID
                            }
                    $ProcessesActivity += $obj                    
                }            
              }           
           }
           
           "CreateFile" {
                if ($Event.Result -eq 'SUCCESS')
                {
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    
                    if($FilteredProcesses -notcontains $currentProcess)
                    {
                        $obj = new-object psobject -Property @{
                                                            Time = $CreateTime
                                                            ProcessName = $currentProcess
                                                            Path = $currentPath                                                            
                            }
                        $FilesCreatedList += $obj                    
                    }            
                }
            
           }

           "SetRenameInformationFile" {
                if ($Event.Result -eq 'SUCCESS')
                {
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    
                    if($FilteredProcesses -notcontains $currentProcess)
                    {
                        $obj = new-object psobject -Property @{
                                                            Time = $CreateTime
                                                            ProcessName = $currentProcess
                                                            Path = $currentPath                                                            
                            }
                        $FilesRenamedList += $obj                    
                    }            
                }
            
           }

           "SetDispositionInformationFile" {
                if ($Event.Result -eq 'SUCCESS')
                {
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    
                    if($FilteredProcesses -notcontains $currentProcess)
                    {
                        $obj = new-object psobject -Property @{
                                                            Time = $CreateTime
                                                            ProcessName = $currentProcess
                                                            Path = $currentPath                                                            
                            }
                        $FileDeletedList += $obj                    
                    }            
                }
            
           }

           "RegCreateKeysListKey" {
                if ($Event.Result -eq 'SUCCESS')
                {
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    
                    if($FilteredProcesses -notcontains $currentProcess)
                    {
                        $obj = new-object psobject -Property @{
                                                            Time = $CreateTime
                                                            ProcessName = $currentProcess
                                                            Path = $currentPath                                                            
                            }
                        $RegCreateKeysList += $obj                    
                    }            
                }
            
           }

            "RegSetValuesListValue" {
                if ($Event.Result -eq 'SUCCESS')
                {
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    
                    if($FilteredProcesses -notcontains $currentProcess)
                    {
                        $LengthLocation = $Event.Detail.IndexOf("Length:")+8
                        $CommaLocation = $Event.Detail.IndexOf(",",$LengthLocation)
                        if ($CommaLocation -gt 0)
                        {
                            $DataLength =  $Event.Detail.Substring($LengthLocation,  $Event.Detail.IndexOf(",",$LengthLocation)-$LengthLocation)
                        }
                        else
                        {
                            $DataLength = ''
                        }
                        

                        if (isNumeric($DataLength))
                        {
                            $strValue = $Event.Detail.Substring($Event.Detail.IndexOf("Data: ")+6)
                            $obj = new-object psobject -Property @{
                                                            Time = $CreateTime
                                                            ProcessName = $currentProcess
                                                            Value = $strValue
                                                            Path = $currentPath                                                            
                            }
                            
                        }
                        else
                        {
                            $obj = new-object psobject -Property @{
                                                                Time = $CreateTime
                                                                ProcessName = $currentProcess
                                                                Value = ''
                                                                Path = $currentPath                                                            
                                }
                        }
                        $RegSetValuesList += $obj                    
                    }            
                }
            
           }

           "RegDeleteValue" {
                
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    
                    if($FilteredProcesses -notcontains $currentProcess)
                    {                       
                        
                         
                            $obj = new-object psobject -Property @{
                                                                Time = $CreateTime
                                                                ProcessName = $currentProcess                                                                
                                                                Path = $currentPath 
                            }                                                           
                       
                        $RegDeleteValuesList += $obj                    
                    }
                }

             "RegDeleteKey" {
                
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    
                    if($FilteredProcesses -notcontains $currentProcess)
                    {                       
                        
                         
                            $obj = new-object psobject -Property @{
                                                                Time = $CreateTime
                                                                ProcessName = $currentProcess                                                                
                                                                Path = $currentPath 
                            }                                                           
                       
                        $RegDeleteValuesList += $obj                    
                    }
                }

                "UDP Send" {
                
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    $RemoteServers  += $currentPath.Split()[2].split(":")[0]
                    if($FilteredProcesses -notcontains $currentProcess)
                    {                       
                        
                         
                            $obj = new-object psobject -Property @{
                                                                Time = $CreateTime
                                                                ProcessName = $currentProcess  
                                                                Protocol = "UDP"                                                                                                                         
                                                                Path = $currentPath 
                            }                                                           
                       
                        $NetworkTraffic += $obj                    
                    }
                }

                 "UDP Receive" {
                
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    $RemoteServers  += $currentPath.Split()[2].split(":")[0]

                    if($FilteredProcesses -notcontains $currentProcess)
                    {                       
                        
                         
                            $obj = new-object psobject -Property @{
                                                                Time = $CreateTime
                                                                ProcessName = $currentProcess  
                                                                Protocol = "UDP"                                                                  
                                                                Path = $currentPath 
                            }                                                           
                       
                        $NetworkTraffic += $obj                    
                    }
                }

                "TCP Send" {
                
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    $RemoteServers  += $currentPath.Split()[2].split(":")[0]

                    if($FilteredProcesses -notcontains $currentProcess)
                    {                       
                        
                         
                            $obj = new-object psobject -Property @{
                                                                Time = $CreateTime
                                                                ProcessName = $currentProcess  
                                                                Protocol = "TCP"                                                                                                                         
                                                                Path = $currentPath 
                            }                                                           
                       
                        $NetworkTraffic += $obj                    
                    }
                }

                 "TCP Receive" {
                
                    $currentProcess = $Event.Process_Name
                    $currentPath    = $Event.Path
                    $CreateTime     = [DateTime]$Event.Time_of_Day
                    $RemoteServers  += $currentPath.Split()[2].split(":")[0]

                    if($FilteredProcesses -notcontains $currentProcess)
                    {                       
                        
                         
                            $obj = new-object psobject -Property @{
                                                                Time = $CreateTime
                                                                ProcessName = $currentProcess  
                                                                Protocol = "TCP"                                                                  
                                                                Path = $currentPath 
                            }                                                           
                       
                        $NetworkTraffic += $obj                    
                    }
                }                      
         }
    } # end ForEach
    ConsoleWrite
}