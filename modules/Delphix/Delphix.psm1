# All functions are defined in their own script files.

# When the module is unloaded, clean up the global session variable
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  Remove-Variable -Name "__DelphixSession" -Scope Global -ErrorAction SilentlyContinue
}