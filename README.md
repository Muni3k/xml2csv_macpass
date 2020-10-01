Program was created for personal usage.
Main problem: how to export data from KDBX and import it to the KeyChain (iCloud) on MacOS?
I had been moved from Windows to MacOS recently and I had to change password manager - from KeePass to MacPass (both supports KDBX files).
I recommend doing periodical manual synchronization between KDBX and KeyChain to have always updated passwords. I do that every month.
I also strongly recommend reading warnings included in the bash script before starting.

Short manual:
1. In Safari go to and delete current passwords: Preferences > Passwords > Cmd+A > Remove (Mac may freeze)
2. Export passwords from MacPass to XML (save it to local disk) and convert it into CSV file (sh xml2csv.sh FILENAME)
3. In Firefox go to and import CSV file: Preferences > Privacy & Security > Import/Export Passwords > Import Passwords (check also import faults). Force close Firefox.
4. In Safari go to and import passwords from Firefox: File > Import From > Firefox > Passwords > Import (Safari may freeze; wait for confirmation message)
5. Delete all passwords from Firefox and XML/CSV files from local disk

Why Firefox?
You have to have Firefox 56 because this is the latest version that have possibility to import passwords.
But why Firefox?
Because there is no possibility to import XML/CSV files into Safari. You can just import passwords from another browser like Firefox.

Download Firefox version 56:
https://download-installer.cdn.mozilla.net/pub/firefox/releases/56.0.2/mac/en-US/Firefox%2056.0.2.dmg
TURN OFF AUTOMATIC UPDATES IMMEDIATELY !!!
Install plugin Password Exporter:
https://addons.mozilla.org/en-US/firefox/addon/password-exporter/

In case of problems or suggestions please contact me!
Tested on Apple MacBook Air 13" 2017 (macOS Mojave 10.14)
@@@ Juliusz Sałek - 10/2018 @@@

#edit 10/2020
Remarks after 2 years:
- No faults after such long time (macOS 10.15.6)
- New Safari 14 shows completion of importing passwords from Firefox
- Currently Firefox during sending data to Safari has to be closed