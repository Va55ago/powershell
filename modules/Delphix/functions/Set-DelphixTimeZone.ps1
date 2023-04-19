function Set-DelphixTimeZone {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess)]
  param(
    # The type of Delphix engine
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$TimeZone
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "service/time")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type           = "TimeConfig"
            systemTimeZone = "$($TimeZone)"
            ntpConfig      = @{
              enabled = $false
              type    = "NTPConfig"
            }
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
    Sets the time zone of the Delphix engine
  .DESCRIPTION
    Sets the time zone of the Delphix engine
  .EXAMPLE
    > Set-DelphixEngineType -TimeZone "Europe/London"
      Sets the time zone of the Delphix engine to "Europe/London"
  #>
}
