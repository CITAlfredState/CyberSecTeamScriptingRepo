@{
	# Script module or binary module file associated with this manifest
	RootModule = 'UserRights.dll'

	# Version number of this module.
	ModuleVersion = '0.5'

	# ID used to uniquely identify this module
	GUID = 'cdd3c946-024b-44c6-a14c-152400ac77ec'

	# Author of this module
	Author = 'Raimund Andree'

	# Company or vendor of this module
	CompanyName = 'Raimund Andree'

	# Copyright statement for this module
	Copyright = '2014'

	# Description of the functionality provided by this module
	Description = 'Windows PowerShell Module for managing user rights'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '2.0'

	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '4.0'

	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @('UserRights.format.ps1xml')

	# List of all modules packaged with this module
	ModuleList = @('UserRights.dll')

	# List of all files packaged with this module
	FileList = @('UserRights.dll', 'UserRights.format.ps1xml', 'UserRights.psd1')
}