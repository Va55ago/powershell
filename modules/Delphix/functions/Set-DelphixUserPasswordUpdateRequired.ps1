function Set-DelphixUserPasswordUpdateRequired {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess)]
  param(
    # Reference of the user whose password update policy is to be updated
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$UserReference,

    # Whether or not the Delphix users needs to update their password on next login
    [Parameter(Position = 1)]
    [bool]$PasswordUpdateRequired = $true
  )
  begin {
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "user/$($UserReference)")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type                    = "User"
            passwordUpdateRequested = $false
          }
        )))

      if ($response.status -ieq "ERROR") {
        throw $response.error
      }
    }
  }
  end {}

  <#
  .SYNOPSIS
    Change the password of the specified user
  .DESCRIPTION
    Change the password of the specified user
  .EXAMPLE
    > Set-DelphixUserPasswordUpdateRequired -UserReference "USER-1" -PasswordUpdateRequired $false
      Sets the Delphix user with reference "USER-1" to not need to update their password on next login
  #>
}
