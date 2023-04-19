function Register-DelphixEngine {
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
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "registration/status")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type   = "RegistrationStatus"
            status = "REGISTERED"
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
    Registers the Delphix engine
  .DESCRIPTION
    Sets the Registration status of the Delphix engine to "REGISTERED"
  .EXAMPLE
    > Register-DelphixEngine
    Registers the Delphix engine
  #>
}
