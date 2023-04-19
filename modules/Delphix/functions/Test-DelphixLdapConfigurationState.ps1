#Requires -Version 7.0

function Test-DelphixLdapConfigurationState {
  [CmdletBinding(SupportsShouldProcess)]
  param()
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "service/ldap")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "GET" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck

      if ($response.status -ieq "ERROR") {
        throw $response.error
      }
      
      return ($response.result) -and ($response.result.enabled)
    }
  }
  end {}

  <#
  .SYNOPSIS
    Determines whether the Delphix engine has already been configured for LDAP integration.
  .DESCRIPTION
    Determines whether the Delphix engine has already been configured for LDAP integration.
  .EXAMPLE
    > Test-DelphixLdapConfigurationState
  .OUTPUTS
    Boolean
    `true` if the Delphix engine has already been configured for LDAP. Otherwise `false`
  #>
}
