#Requires -Version 7.0

function Resolve-LdapServerHosts {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess)]
  param(
    # The fully qualified name of the domain
    [Parameter(Mandatory, Position=0, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string]$Fqdn
  )
  begin {}
  process {
    if ($PSCmdlet.ShouldProcess($Fqdn)) {
      $ipAddresses = @([System.Net.Dns]::GetHostAddresses($Fqdn) |
        Where-Object -FilterScript { $_.AddressFamily -eq "InterNetwork" })

      if (-not $ipAddresses) {
        throw "Unable to resolve IP addresses of FQDN: '$Fqdn'"
      }

      return $ipAddresses | ForEach-Object -Process { [System.Net.Dns]::GetHostEntry($_) } | Select-Object -Unique HostName
    }
  }
  end {}

  <#
  .SYNOPSIS
    Gets the fully qualified names of all the hosts providing the LDAP service
  .DESCRIPTION
    Gets the fully qualified names of all the hosts providing the LDAP service
  .EXAMPLE
    > Resolve-LdapServerHosts -Fqdn "iaglobal.lloydstsb.com"
      Gets the FQDNs of the domain controllers of the iaglobal.lloydstsb.com domain
  .OUTPUTS
    string[]
    A list of fully qualified names of all the hosts providing the LDAP service
  #>
}
