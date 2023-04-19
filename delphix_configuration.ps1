#Requires -PSEdition Core
#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, PositionalBinding)]
param(
  # Base URI of the Delphix REST API
  [Parameter(Mandatory, ValueFromPipeline, Position=0)]
  [ValidateNotNullOrEmpty()]
  [System.Uri]$BaseUri,

  # Version of the target Delphix Engine
  [Parameter(Mandatory, Position=1)]
  [ValidateNotNullOrEmpty()]
  [version]$Version,

  # The FQDN of the domain to which Delphix should be configured for LDAP integration
  [Parameter(Mandatory, Position=1)]
  [ValidateNotNullOrEmpty()]
  [string]$LdapDomain = "iaglobal.lloydstsb.com",

  # The port of the domain to which Delphix should be configured for LDAP integration
  [Parameter(Mandatory, Position=1)]
  [ValidateNotNullOrEmpty()]
  [string]$LdapsPort = 636
)
begin {
  Import-Module "$($PSScriptRoot)/modules/Delphix" -DisableNameChecking -Verbose:$false
}
process {
  Enter-DelphixSession -BaseUri $BaseUri -Version $Version -Verbose:$VerbosePreference

  #region Get default sysadmin and admin user credentials

  # Initial sysadmin password is just "sysadmin"
  [securestring]$sysAdminPassword = ConvertTo-SecureString -String "sysadmin" -AsPlainText -Force
  $sysAdminCredential = New-Object System.Management.Automation.PSCredential ("sysadmin", $sysAdminPassword)

  # Initial admin password is just "delphix"
  [securestring]$adminPassword = ConvertTo-SecureString -String "delphix" -AsPlainText -Force
  $adminCredential = New-Object System.Management.Automation.PSCredential ("admin", $adminPassword)

  #endregion

  $sysAdminUserRef = Login-Delphix -Credential $sysAdminCredential -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference

  $delphixIsInitialized = Test-DelphixInitializationState `
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference

  if (-not $delphixIsInitialized) {
    # Initialize the Delphix appliance
    Initialize-DelphixEngine `
      -DefaultAdminCredential $adminCredential `
      -Verbose:$VerbosePreference `
      -WhatIf:$WhatIfPreference

    # Initialising the engine logs us out, so we have to recreate a new session and login again
    
    Enter-DelphixSession -BaseUri $BaseUri -Version $Version -Verbose:$VerbosePreference
    
    Login-Delphix -Credential $sysAdminCredential -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference | Out-Null
  }

  # Register the Delphix appliance
  Register-DelphixEngine `
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference

  $delphixEngineType = Get-DelphixEngineType `
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference

  if ($delphixEngineType -ieq "UNSET") {
    # Set the Delphix engine type to Database Virtualisation mode
    Set-DelphixEngineType `
      -EngineType "VIRTUALIZATION" `
      -Verbose:$VerbosePreference `
      -WhatIf:$WhatIfPreference
  }

  # Set the TimeZone to London (GMT)
  Set-DelphixTimeZone `
    -TimeZone "Europe/London" `
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference

  # Allow only HTTPS connections
  Set-DelphixHttpMode `
    -HttpMode "HTTPS_ONLY" `
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference

  # Disable Delphix's Phone Home service
  Disable-DelphixPhoneHome `
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference

  # Disable Delphix's usage analytics service
  Disable-DelphixUsageAnalytics `
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference

  # Import LDAP Server certificates
  $ldapServers = Resolve-LdapServerHosts `
    -Fqdn $LdapDomain `
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference

  $ldapServers.HostName | Invoke-DelphixCertificateImport `
    -Port $LdapsPort `
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference

  # Configure LDAP integration
  if (-not (Test-DelphixLdapConfiguration)) {
    
  }
}
end {
  Remove-Module Delphix -Verbose:$false -WhatIf:$false
}

<#
.SYNOPSIS
  Performs initial configuration of a Delphix Engine
.NOTES
  PowerShell does not properly propogate preference variables into script functions
  that are defined in Modules, For more information, see https://github.com/PowerShell/PowerShell-RFC/pull/221

  The workaround is to explicitly pass the preferences to the module functions.
  That's the reason all the function calls below include:
    -Verbose:$VerbosePreference `
    -WhatIf:$WhatIfPreference
#>