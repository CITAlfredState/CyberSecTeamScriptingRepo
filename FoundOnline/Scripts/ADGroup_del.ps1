#######################################################################################
Author: Ramkumar Natarajan : http://in.linkedin.com/pub/ramkumar-natarajan/26/146/850 
Date: 13.03.2015
Comment: Delete list of ADgroups given in tex file
#######################################################################################-


import-module activedirectory

$erroractionpreference = “SilentlyContinue” 

##you may exclude the excel reporting if not required.
 
$a = New-Object -comobject Excel.Application 
$a.visible = $True

$b = $a.Workbooks.Add() 
$c = $b.Worksheets.Item(1)

$c.Cells.Item(1,1) = “AD Groupname” 
$c.Cells.Item(1,2) = “Status” 
$c.Cells.Item(1,3) = “Date & Time ” 
$c.Cells.Item(1,4) = " Accidental Deletion "

$d = $c.UsedRange 
$d.Interior.ColorIndex = 19 
$d.Font.ColorIndex = 11 
$d.Font.Bold = $True 
$d.EntireColumn.AutoFit()
$intRow = 2

# If need to delete groups by wildcard serach.

# Get-ADGroup -Filter {name -like "*-Computers-AppDeploy-*"} -Properties Name | format-table  Name -autosize | out-file C:\temp\Group.txt
	
$groups = Get-Content ("C:\temp\Group.txt")

foreach($g in $groups)
{

#If need to get protectedFromAccidentalDeletion status.

	$Accdel = Get-ADGroup $group -Properties ProtectedFromAccidentalDeletion | select-object ProtectedFromAccidentalDeletion 

#Command to remove the ADgroups

	$g= Remove-ADGroup $g -confirm:$false

#verify the group has been deleted or not but it will take some time to reflect in directory so you need to verify using wildcard search after the execution completed.

   $GG= Get-ADGroup $g 
        
if($GG.Name -eq $null )
    {
        
    $c.Cells.Item($intRow, 1) = $GG.ToUpper() 
    $c.Cells.Item($intRow, 2) = "Group is still existing"
    $c.Cells.Item($intRow, 3) = get-date
    $c.cells.item($introw, 4) =  "$Accdel"        
    $intRow = $intRow + 1
    }
    else
    {
        
    $c.Cells.Item($intRow, 1) = $GG.ToUpper() 
    $c.Cells.Item($intRow, 2) = "Successfully Deleted "
    $c.Cells.Item($intRow, 3) = get-date
    $c.cells.item($introw, 4) =  "$Accdel"   
    $intRow = $intRow + 1
    }
  

}

$d.EntireColumn.AutoFit()
$b.SaveAs("c:\Temp\Status.csv")
$a.Quit()
