param (
    [string]$connstr
)

$downloadJob = start-job -scriptblock {
mkdir C:\Exercise
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$wc = new-object System.Net.WebClient
$wc.DownloadFile("https://github.com/MicrosoftDocs/mslearn-app-service-migration-assistant/releases/download/1.0/WebDeploy_amd64_en-US.msi", "C:\Exercise\WebDeploy_amd64_en-US.msi")
$wc.DownloadFile("https://github.com/MicrosoftDocs/mslearn-app-service-migration-assistant/releases/download/1.0/AppServiceMigrationAssistant.1.0.3.msi", "C:\Exercise\AppServiceMigrationAssistant.1.0.3.msi")
$wc.DownloadFile("https://github.com/MicrosoftDocs/mslearn-app-service-migration-assistant/releases/download/1.0/partsunlimitedwebsite.zip", "C:\Exercise\partsunlimitedwebsite.zip")
$wc.DownloadFile("https://github.com/MicrosoftDocs/mslearn-app-service-migration-assistant/releases/download/1.0/partsunlimitedwebsite.deploy.cmd", "C:\Exercise\partsunlimitedwebsite.deploy.cmd")
$wc.DownloadFile("https://github.com/MicrosoftDocs/mslearn-app-service-migration-assistant/releases/download/1.0/partsunlimitedwebsite.SetParameters.xml", "C:\Exercise\partsunlimitedwebsite.SetParameters.xml")
$wc.DownloadFile("https://raw.githubusercontent.com/MicrosoftDocs/mslearn-app-service-migration-assistant/master/setup.sql", "C:\Exercise\setup.sql")

Start-Process "msiexec.exe" -ArgumentList '/I C:\Exercise\WebDeploy_amd64_en-US.msi /qn /norestart ADDLOCAL=ALL' -Wait -NoNewWindow
Start-Process "msiexec.exe" -ArgumentList '/I "C:\Exercise\AppServiceMigrationAssistant.1.0.3.msi" /qn /norestart ALLUSERS=1' -Wait -NoNewWindow

$sql = get-content C:\Exercise\setup.sql
$cn = new-object system.data.SqlClient.SQLConnection($connstr);
$cmd = new-object system.data.sqlclient.sqlcommand($sql, $cn);
$cn.Open();
$cmd.ExecuteNonQuery();
$cn.Close();
}

install-windowsfeature -name web-server,web-mgmt-console,web-mgmt-service,web-asp-net45,web-http-redirect,web-custom-logging,web-log-libraries,web-request-monitor,web-http-tracing,web-basic-auth,web-windows-auth,web-appinit

set-webconfigurationproperty "system.applicationHost/applicationPools/add[@name='DefaultAppPool']" -name "enable32BitAppOnWin64" -value "True"

$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force


wait-job $downloadJob

(Get-Content c:\Exercise\partsunlimitedwebsite.SetParameters.xml).replace('[connection_string]', $connstr) | Set-Content c:\Exercise\partsunlimitedwebsite.SetParameters.xml
& C:\Exercise\partsunlimitedwebsite.deploy.cmd /Y

try { Invoke-WebRequest http://localhost -TimeoutSec 1 -UseBasicParsing } catch { }
