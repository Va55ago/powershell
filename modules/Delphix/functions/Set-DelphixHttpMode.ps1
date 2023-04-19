function Set-DelphixHttpMode {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess)]
  param(
    [Parameter(Mandatory, ValueFromPipeline, Position=0)]
    [ValidateSet("HTTP_ONLY", "HTTPS_ONLY", "HTTP_REDIRECT", "BOTH", "HTTP_REDIRECT_WITH_HSTS")]
    [string]$HttpMode
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "service/httpConnector")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type     = "HttpConnectorConfig"
            httpMode = $HttpMode
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
    Sets the HTTP mode of the Delphix Engine
  .DESCRIPTION
    Sets the HTTP mode of the Delphix Engine
  .EXAMPLE
    > Set-DelphixHttpMode -HttpMode "HTTPS_ONLY"
    Configures the Delphix engine to accept only HTTPS requests
  #>
}
