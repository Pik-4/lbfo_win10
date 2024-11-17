mkdir extracted

set SevenZipPath="C:\Program Files\7-zip\7z.exe"
set InstallWim=install.wim
set ImageIndex=4
set CatalogGUID={F750E6C3-38EE-11D1-85E5-00C04FC295EE}
set CatalogName=Microsoft-Windows-Server-Features-Package015~31bf3856ad364e35~amd64~~10.0.20348.558.cat
set CatalogName2=Microsoft-Windows-ServerCore-Drivers-merged-Package~31bf3856ad364e35~amd64~~10.0.20348.587.cat

set PathsToExtract=%ImageIndex%\Windows\System32\CatRoot\%CatalogGUID%\%CatalogName%
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\CatRoot\%CatalogGUID%\%CatalogName2%
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\drivers\mslbfoprovider.sys
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\drivers\en-US\mslbfoprovider.sys.mui
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\DriverStore\en-US\MsLbfoProvider.inf_loc
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\DriverStore\FileRepository\mslbfoprovider.inf_amd64_*

%SevenZipPath% x -aoa -o.\extracted %InstallWim% %PathsToExtract%

sigcheck64 -accepteula -i -f .\extracted\%ImageIndex%\Windows\System32\CatRoot\%CatalogGUID%\%CatalogName% .\extracted\%ImageIndex%\Windows\System32\drivers\mslbfoprovider.sys
sigcheck64 -accepteula -i -f .\extracted\%ImageIndex%\Windows\System32\CatRoot\%CatalogGUID%\%CatalogName2% .\extracted\%ImageIndex%\Windows\System32\DriverStore\FileRepository\mslbfoprovider.inf_amd64_f9d27a6b05ef21aa\mslbfoprovider.inf
