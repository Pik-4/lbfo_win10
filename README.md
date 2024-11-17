https://github.com/gsuberland/lbfo_win10/issues/1#issuecomment-1250090585

First of all. If you have already tried to use this and specially if you tried the "Have disk" method you need to do some cleaning. If someone reading this did not try to do this before, then skip this cleaning part and proceed to the installation part below.
--Cleaning:

1. Delete the 6 (or 5 if you did not copy the second catalog file) that were installed with `install.bat`
2. Go to `C:\Windows\INF` and use a search in files tool (Notepad++ works great for this) to find all `oemx.inf` files that contain `mslbfoprovider` in them. Those are the files that got installed every time you tried the "Have disk" method. Ideally it should only be one, but there could be more depending on what you tried. NOTE down their names and delete them (along with their associated `.PNF` file if it exists. Eg: `oem11.inf` and `oem11.PNF`)
3. Run `psexec -s -i regedit.exe` to get into the registry editor as the `SYSTEM` user. Select `HKLM` and go to `File` and select `Load Hive`. Go to `C:\Windows\system32\config` select `DRIVERS` hive file and open it. When asked what to mount it as type `DRIVERS`.
   Go now under `HKLM\DRIVERS\DriverDatabase` and search under the 4 sub keys there for any instances of the `oemxx.inf` files that you noted down and deleted on cleaning step 2. Delete all the keys pertaining to them, close regedit and reboot.

Ok now we're at a clean state and it's time to install. I use the files from the `June 2022` update of the `Windows Server 2022 Datacenter Standard Edition` (not Evaluation). If you're are using a different iso you need to install it in a VM to find the proper files and adjust the below accordingly.

--Installation:

1. Clone this repo if you have not already and extract `install.wim` from your iso to the directory you got from cloning the repo.
2. Edit `extract.bat` so that it looks like this:

```
mkdir extracted

set SevenZipPath="C:\Program Files\7-zip\7z.exe"
set InstallWim=install.wim
set ImageIndex=4
set CatalogGUID={F750E6C3-38EE-11D1-85E5-00C04FC295EE}
set CatalogName=Microsoft-Windows-Server-Features-Package015~31bf3856ad364e35~amd64~~10.0.20348.740.cat
set CatalogName2=Microsoft-Windows-ServerCore-Drivers-merged-Package~31bf3856ad364e35~amd64~~10.0.20348.681.cat

set PathsToExtract=%ImageIndex%\Windows\System32\CatRoot\%CatalogGUID%\%CatalogName%
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\CatRoot\%CatalogGUID%\%CatalogName2%
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\drivers\mslbfoprovider.sys
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\drivers\en-US\mslbfoprovider.sys.mui
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\DriverStore\en-US\MsLbfoProvider.inf_loc
set PathsToExtract=%PathsToExtract% %ImageIndex%\Windows\System32\DriverStore\FileRepository\mslbfoprovider.inf_amd64_*

%SevenZipPath% x -aoa -o.\extracted %InstallWim% %PathsToExtract%

sigcheck64 -accepteula -i -f .\extracted\%ImageIndex%\Windows\System32\CatRoot\%CatalogGUID%\%CatalogName% .\extracted\%ImageIndex%\Windows\System32\drivers\mslbfoprovider.sys
sigcheck64 -accepteula -i -f .\extracted\%ImageIndex%\Windows\System32\CatRoot\%CatalogGUID%\%CatalogName2% .\extracted\%ImageIndex%\Windows\System32\DriverStore\FileRepository\mslbfoprovider.inf_amd64_f9d27a6b05ef21aa\mslbfoprovider.inf
```



Note: I use sigcheck64, if you use x86 version replace sigcheck64 with sigcheck.

1. Edit `install.bat` so that it looks like this:

```
set ImageIndex=4

xcopy /H /Y /E .\extracted\%ImageIndex% C:\
reg import mslbfo_service.reg
reg import mslbfo_network_provider.reg
reg import mslbfo_eventlog.reg
reg import Drivers-DeviceIds.reg
reg import Drivers-DriverInfFiles.reg
reg import Drivers-DriverPackages.reg
sigcheck64 -accepteula -i c:\windows\system32\drivers\mslbfoprovider.sys
```



1. Create these 3 `.reg` files:
   Drivers-DeviceIds.reg:

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\DRIVERS\DriverDatabase\DeviceIds\ms_lbfo]
"mslbfoprovider.inf"=hex:01,ff,00,00
```



Drivers-DriverInfFiles.reg:

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\DRIVERS\DriverDatabase\DriverInfFiles\mslbfoprovider.inf]
@=hex(7):6d,00,73,00,6c,00,62,00,66,00,6f,00,70,00,72,00,6f,00,76,00,69,00,64,\
  00,65,00,72,00,2e,00,69,00,6e,00,66,00,5f,00,61,00,6d,00,64,00,36,00,34,00,\
  5f,00,66,00,39,00,64,00,32,00,37,00,61,00,36,00,62,00,30,00,35,00,65,00,66,\
  00,32,00,31,00,61,00,61,00,00,00,00,00
"Active"="mslbfoprovider.inf_amd64_f9d27a6b05ef21aa"
```



Drivers-DriverPackages.reg:

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\DRIVERS\DriverDatabase\DriverPackages\mslbfoprovider.inf_amd64_f9d27a6b05ef21aa]
"Version"=hex:ff,ff,09,00,00,00,00,00,74,e9,36,4d,25,e3,ce,11,bf,c1,08,00,2b,\
  e1,03,18,00,80,8c,a3,c5,94,c6,01,01,00,7c,4f,00,00,0a,00,00,00,00,00,00,00,\
  00,00
"Provider"="Microsoft"
"SignerScore"=dword:0d000003
"FileSize"=hex(b):aa,0c,00,00,00,00,00,00
@="mslbfoprovider.inf"
```



1. Edit `mslbfo_service.reg` and set `Start"=dword:00000003` to either `1` (automatic start for kernel mode drivers only) or `2` automatic. Because `3` is manual and on reboot your NIC team will not go up. `1` is better in this case as it gets up sooner.
2. Now run `psexec -s -i regedit.exe`. Once the registry editor loads, select `HKLM` then `File` and `Load hive`. Go to `C:\Windows\system32\config` select `DRIVERS` hive file and open it. When asked what to mount it as type `DRIVERS`.
   (We are doing this in order to load the hive that we need for our 3 `.reg` files to import. A normal Administrator user does not have access to that hive and `SYSTEM` user does not automatically load the hive. The hive will stay mounted for the 'SYSTEM' user until reboot.)
3. Exit the registry editor and run `psexec -s -i cmd.exe`. At the new command prompt running under `SYSTEM` user, go to the directory with our files and run `extract.bat`. Once it's done, run `install.bat`.
4. Reboot.
5. Don't try to load the Network Service or anything of the sort. Go to powershell and create your teams directly. The service is now available on the system and `new-NetLBFOTeam` applet will add it where it needs to add it on its own.
6. If when the Team NIC goes up, one or more NICs are not properly added to the Team, it means that while you where testing/trying to make this work, these member NICs got corrupted registry entries. In which case you need to delete the Team via powershell, go to `Network & Internet Settings`, `Advanced Network Settings` and do `Network Reset`. Reboot and recreate the Team. (You will have to reconfigure the NICs, obviously.)

That's it.

PS Sorry for being so descriptive but I wanted to leave no room for error.