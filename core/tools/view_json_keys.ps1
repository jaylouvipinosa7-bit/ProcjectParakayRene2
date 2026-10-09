$txt = [System.IO.File]::ReadAllText("c:\Users\pc\Downloads\ano na\base_app_step_2086.json")
$obj = $txt | ConvertFrom-Json
$tc = $obj.tool_calls[0]
Write-Host "Tool name: $($tc.name)"
Write-Host "TargetFile: $($tc.args.TargetFile)"
Write-Host "Description: $($tc.args.Description)"
