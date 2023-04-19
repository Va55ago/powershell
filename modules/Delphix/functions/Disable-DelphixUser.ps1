function Disable-DelphixUser {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    # Reference of the user to be disabled
    [Parameter(Mandatory, ValueFromPipeline, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$UserReference
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "user/$UserReference/disable")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck;
      
      if ($response.status -ieq "ERROR") {
        throw $response.error
      }
      return $response.result
    }
  }
  end {}
  
  <#
  .SYNOPSIS
    Disables a Delphix user account
  .DESCRIPTION
    Disables a Delphix user account
  .EXAMPLE
    > Disable-DelphixUser -UserReference "USER-1"

    Disables the user with reference "USER-1"
  #>
}
