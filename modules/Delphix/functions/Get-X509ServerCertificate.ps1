#Requires -Version 7.0

function Get-X509ServerCertificate {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess)]
  param(
    # The fully qualified domain name of the service that is presenting the X509 certificate
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$Fqdn,

    # The port number of the service that is presenting the X509 certificate
    [Parameter(Mandatory, Position=0)]
    [ValidateRange(0, 65535)]
    [int]$Port
  )
  begin {}
  process {
    if ($PSCmdlet.ShouldProcess("$($Fqdn):$($Port)")) {
      # Get the first valid IP address for the FQDN
      $ipAddress = [System.Net.Dns]::GetHostEntry($Fqdn).AddressList[0]

      # Open a TCP connection to that IP address and grab the certificate that it presents
      $tcpSocket = [System.Net.Sockets.TcpClient]::new($ipAddress, $Port)
      try {
        $tcpStream = $tcpSocket.GetStream()
        $callback = { param($dummy, $cert, $chain, $errors) return $true }
        $sslStream = [System.Net.Security.SslStream]::new($tcpStream, $true, $callback)
        try {
          $sslStream.AuthenticateAsClient($ipAddress)
          $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($sslStream.RemoteCertificate)
        }
        finally {
          $sslStream.Dispose()
        }
      }
      finally {
        $tcpSocket.Dispose()
      }

      return $certificate
    }
  }
  end {}

  <#
  .SYNOPSIS
    Gets the X509 certificate presented by an FQDN on a given port
  .DESCRIPTION
    Gets the X509 certificate presented by an FQDN on a given port
  .EXAMPLE
    > Get-X509ServerCertificate -Fqdn "iaglobal.lloydstsb.com" -Port 
      Gets the FQDNs of the domain controllers of the iaglobal.lloydstsb.com domain
  .OUTPUTS
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    The X509 certificate presented by the FQDN on the given port
  #>
}
