function Enter-DelphixSession {
  [CmdletBinding(PositionalBinding)]
  param(
    # Base URI of the Delphix REST API
    [Parameter(Mandatory, ValueFromPipeline, Position=0)]
    [System.Uri]$BaseUri,

    # Version of the target Delphix Engine
    [Parameter(Mandatory, Position=1)]
    [version]$Version
  )
  begin {}
  process {
    $uri = [System.Uri]::new($BaseUri, "session")

    Write-Verbose "Performing the operation 'Enter-DelphixSession' on target '$($BaseUri.DnsSafeHost)'"

    $response = Invoke-RestMethod `
      -Method "POST" `
      -Uri $uri `
      -Headers @{ "Content-Type" = "application/json" } `
      -SessionVariable "webSession" `
      -SkipCertificateCheck `
      -Body ([System.Text.Encoding]::UTF8.GetBytes($(
        ConvertTo-Json -InputObject @{
          type    = "APISession"
          version = @{
            type  = "APIVersion"
            major = $($Version.Major)
            minor = $($Version.Minor)
            micro = $($Version.Build)
          }
        }
      )))

    if ($response.status -ieq "ERROR") {
      throw $response.error
    }
    
    Set-Variable -Name "__DelphixSession" -Scope Global -Value @{
      BaseUri = $BaseUri
      WebSession = $webSession
    }
  }
  end {}

  <#
  .SYNOPSIS
    Creates a new stateful Delphix session
  .DESCRIPTION
    Creates a new stateful Delphix session and sets a global "WebSession" variable
    that will be used by the other cmdlets in this module.
  .EXAMPLE
    > Enter-DelphixSession -BaseUri "https://10.50.238.4/resources/json/delphix/" -Version "1.11.16"
      Creates and enters a new Delphix session
  #>
}
