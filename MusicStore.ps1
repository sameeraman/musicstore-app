

Param (
    [string]$user,
    [string]$password,
    [string]$sqlserver,
    [string]$sqldbname

)


# Force use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Firewall
netsh advfirewall firewall add rule name="http" dir=in action=allow protocol=TCP localport=80

# Folders
New-Item -ItemType Directory c:\temp
New-Item -ItemType Directory c:\music

# Install iis
Install-WindowsFeature web-server -IncludeManagementTools


# Install dot.net core sdk
Invoke-WebRequest http://go.microsoft.com/fwlink/?LinkID=615460 -outfile c:\temp\vc_redistx64.exe
Start-Process c:\temp\vc_redistx64.exe -ArgumentList '/quiet' -Wait
Invoke-WebRequest https://download.visualstudio.microsoft.com/download/pr/c6b9a396-5e7a-4b91-86f6-f9e8df3bf1dd/6d61addfd6069e404981bede03f8f4f9/dotnet-dev-win-x64.1.1.14.exe -outfile c:\temp\DotNetCore.1.0.0-SDK.Preview2-x64.exe
Start-Process c:\temp\DotNetCore.1.0.0-SDK.Preview2-x64.exe -ArgumentList '/quiet' -Wait
Invoke-WebRequest https://download.visualstudio.microsoft.com/download/pr/0cb4f123-a55d-4263-afe2-e54e5fdc1f0e/b9df261ef59d400872dd54107478f2b0/dotnetcore.1.0.14_1.1.11-windowshosting.exe -outfile c:\temp\DotNetCore.WindowsHosting.exe 
Start-Process c:\temp\DotNetCore.WindowsHosting.exe -ArgumentList '/quiet' -Wait

# Download music app
Invoke-WebRequest  https://github.com/Microsoft/dotnet-core-sample-templates/raw/master/dotnet-core-music-windows/music-app/music-store-azure-demo-pub.zip -OutFile c:\temp\musicstore.zip
Expand-Archive C:\temp\musicstore.zip c:\music

# Azure SQL connection sting in environment variable
[Environment]::SetEnvironmentVariable("Data:DefaultConnection:ConnectionString", "Server=$sqlserver;Database=$sqldbname;Integrated Security=False;User Id=$user;Password=$password;MultipleActiveResultSets=True;Connect Timeout=30",[EnvironmentVariableTarget]::Machine)

# Pre-create database
$env:Data:DefaultConnection:ConnectionString = "Server=$sqlserver;Database=$sqldbname;Integrated Security=False;User Id=$user;Password=$password;MultipleActiveResultSets=True;Connect Timeout=30"
Start-Process 'C:\Program Files\dotnet\dotnet.exe' -ArgumentList 'c:\music\MusicStore.dll'

# Configure iis
Remove-WebSite -Name "Default Web Site"
Set-ItemProperty IIS:\AppPools\DefaultAppPool\ managedRuntimeVersion ""
New-Website -Name "MusicStore" -Port 80 -PhysicalPath C:\music\ -ApplicationPool DefaultAppPool
& iisreset
