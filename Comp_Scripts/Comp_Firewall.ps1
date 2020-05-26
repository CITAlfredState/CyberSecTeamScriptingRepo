# Purpose for competitions where outside files aren't allowed
# this script will implicitly deny any port that is not in the array up to 65535
# YOU WILL NEED TO MANUALLY TYPE ANYTHING NOT PREDICATED BY A '#'

# MUST CHANGE ExecutionPolicy from 'Restricted' to 'Remote Signed' for the admin user


Import-Module netsecurity

# Disables all firewall ports that aren't in this array:

$a = @(443, 80)

For($i=0; $i -le 65535; $i++)
{
    foreach($e in $a){
        if($i -ne $e){
            # make port closed
            New-NetFirewallRule -Name "Block $i In" -Direction Inbound -LocalPort $i -Action Block
            New-NetFirewallRule -Name "Block $i Out" -Direction Outbound -LocalPort $i -Action Block
        }
        else(){
            # do nothing
        }

    }
}