# Purpose for competitions where outside files aren't allowed 
# this script will disable any accounts made past it's intantiation date
# YOU WILL NEED TO MANUALLY TYPE ANYTHING NOT PREDICATED BY A '#'

# Local: must be run by a local machine admin
# Must Enable 'Audit account management' in 'Local Group Policy Editor' 


# manually schedule this task with Task Manager
# Manually set date in format "dddd MM/dd/yyyy HH:mm K"
$d = 5/20/2020
$adu = Get-LocalUser

 {whenCreated -gt $d} -Properties whenCreated) | Seclect SIDz
foreach($u in $adu){
    #disable account
}
