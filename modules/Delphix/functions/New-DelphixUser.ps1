#Requires -Version 7.0

function New-DelphixUser {
  [CmdletBinding(PositionalBinding, DefaultParameterSetName="NativeAuth", SupportsShouldProcess)]
  param(
    # Whether this user is a System or Domain user
    [Parameter(Mandatory, Position=0)]
    [ValidateSet("SYSTEM", "DOMAIN")]
    [string]$UserType,

    # The credentials of the new user when using Native authentication
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="NativeAuth", Position=1)]
    [ValidateNotNull()]
    [PSCredential]$Credential,

    # The domain principal to be used for LDAP authentication
    [Parameter(Mandatory, ParameterSetName="LdapAuth", ValueFromPipeline, Position=1)]
    [switch]$Principal,

    # The user's first name
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$FirstName,

    # The user's last name
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LastName,

    # The user's email address
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$EmailAddress,

    # This user's session timeout in minutes
    [Parameter()]
    [ValidateRange(1)]
    [int]$SessionTimeout = 30
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "user")

    if ($PSCmdlet.ParameterSetName -eq "NativeAuth") {
      if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost, "New-DelphixNativeUser")) {
        $response = Invoke-RestMethod `
          -Method "POST" `
          -Uri $uri `
          -Headers @{ "Content-Type" = "application/json" } `
          -WebSession $delphixSession.Value.WebSession `
          -SkipCertificateCheck `
          -Body ([System.Text.Encoding]::UTF8.GetBytes($(
            ConvertTo-Json -InputObject @{
              type               = "User"
              userType           = $UserType
              name               = $Credential.Username
              authenticationType = "NATIVE"
              credential = @{
                type     = "PasswordCredential"
                password = (ConvertFrom-SecureString -SecureString $Credential.Password -AsPlainText)
              }
              email                 = $EmailAddress
              enabled               = $true
              firstName             = $FirstName
              lastName              = $LastName
              locale                = "en-GB"
              sessionTimeout        = $SessionTimeout
            }
          )))

        if ($response.status -ieq "ERROR") {
          throw $response.error
        }
        return $response.result
      }
    }
    else {
      if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost, "New-DelphixLdapUser")) {
        $response = Invoke-RestMethod `
          -Method "POST" `
          -Uri $uri `
          -Headers @{ "Content-Type" = "application/json" } `
          -WebSession $delphixSession.Value.WebSession `
          -SkipCertificateCheck `
          -Body ([System.Text.Encoding]::UTF8.GetBytes($(
            ConvertTo-Json -InputObject @{
              type                  = "User"
              userType              = $UserType
              principal             = $Principal
              authenticationType    = "LDAP"
              email                 = $EmailAddress
              enabled               = $true
              firstName             = $FirstName
              lastName              = $LastName
              locale                = "en-GB"
              sessionTimeout        = $SessionTimeout
            }
          )))

        if ($response.status -ieq "ERROR") {
          throw $response.error
        }
        return $response.result
      }
    }
  }
  end {}

  <#
  .SYNOPSIS
    Creates a new Delphix domain user

  .DESCRIPTION
    Creates a new Delphix domain user

  .EXAMPLE
    > $userCredential = Get-Credential -UserName "Breakglass.admin" -Message "Default admin user password"
    > New-DelphixUser `
        -UserType DOMAIN `
        -Credential $userCredential `
        -FirstName "Breakglass" `
        -LastName "Admin" `
        -SessionTimeout 30 `
        -Verbose

      Adds a new Delphix user called "Breakglass.admin" using Delphix Native authentication

    .EXAMPLE
      > New-DelphixUser `
        -UserType DOMAIN `
        -Principal "IAGLOBAL\7702664" `
        -FirstName "Breakglass" `
        -LastName "Admin" `
        -SessionTimeout 30 `
        -Verbose

      Adds the IAGLOBAL\7702664 user to Delphix using LDAP authentication
  #>
}
