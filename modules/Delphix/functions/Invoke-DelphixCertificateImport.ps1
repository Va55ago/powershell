#Requires -Version 7.0

function Invoke-DelphixCertificateImport {
  [CmdletBinding(PositionalBinding, DefaultParameterSetName="NativeAuth", SupportsShouldProcess)]
  param(
    # The fully qualified domain name of the host that is presenting the X509 certificate
    [Parameter(Mandatory, Position=0, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string]$Fqdn,

    # The port number of the host that is presenting the X509 certificate
    [Parameter(Mandatory, Position=1)]
    [ValidateRange(0, 65535)]
    [int]$Port
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-2209DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "service/tls/caCertificate/fetch")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type = "CertificateFetchParameters"
            host = $Fqdn
            port = $Port
          }
        )))

      if ($response.status -ieq "ERROR") {
        # The API call isn't idempotent if the certificate has already been trusted.
        if ($response.error.id -eq "exception.ssl.certificate.fetch.fail.already.accepted") {
          $null = $response.error.details -match "CA_CERTIFICATE-.+$" # Populates the $matches variables
          Write-Verbose "The X509 certificate published by '${Fqdn}' on Port '${Port}' has already been imported into Delphix and is trusted.`n  Certificate reference: '$($matches[0])'"
          return
        }

        throw $response.error
      }

      $certificate = $response.result
      $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "service/tls/caCertificate/$($certificate.reference)/accept")
      if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
        $response = Invoke-RestMethod `
          -Method "POST" `
          -Uri $uri `
          -Headers @{ "Content-Type" = "application/json" } `
          -WebSession $delphixSession.Value.WebSession `
          -SkipCertificateCheck

        if ($response.status -ieq "ERROR") {
          throw $response.error
        }
      }
    }
  }
  end {}

  <#
  .SYNOPSIS
    Fetches the public X509 certificate presented by a host on a given port and imports it into Delphix

  .DESCRIPTION
    Fetches the public X509 certificate presented by a host on a given port and imports it into Delphix.
    Delphix is then instructed to trust that certificate.

  .EXAMPLE
    > Invoke-DelphixCertificateImport -Fqdn "dcrdiv0057.iaglobal.lloydstsb.com" -Port 636 -Verbose

      Fetches the public X509 certificate presented by the host 'dcrdiv0057.iaglobal.lloydstsb.com'
      on port 636 and imports it into Delphix.
  #>
}
