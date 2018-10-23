#!/bin/bash

### USAGE ###
# sh xml2csv FILENAME [DELIMETER] [DELIMETER_SUGGEST]
# FILENAME - required argument, name of the xml file, without extension, tested on xml files from OSX MacPass, output file will be named FILENAME.csv
# DELIMETER - optional argument, forces script to use your own delimiter, see warning no 1 for details, enter just one ASCII char
# DELIMETER_SUGGEST - optional argument, script will present suggested delimiters based on output csv file, to enable enter 'suggest'

### WARNING #1 ###
# XML data cannot contain char that is used in sed command as delimiter! #
# Script should be conflict-free in above term but it is not tested for all delimiters! #
# You can also pass as second argument your own delimiter and force script to use it!  #

### WARNING #2 ###
# Due to later csv file import to Firefox it is forbidden to have any URL, username or password with comma! #
# Even if your data contains commas - output csv file will be generated! #
# Quality of that file is not guaranteed!!! Review it before importing to Firefox! #

### WARNING #3 ###
# All entries that does not contain URL or password - will be deleted! #
# This is caused by Firefox passwords importing requirements #

xmlFile="$1" #argumernt no 1 is xml filename without extension

    # remove current csv file
if [ -f $xmlFile.csv ]; then
    rm $xmlFile.csv
fi
    # remove all new lines and create new temporary file
tr -d '\n' < $xmlFile.xml > .xmltocsv.tmp
    # remove all double spaces (tabs in exported file) and create second temporary file
tr -s ' ' < .xmltocsv.tmp > .xmltocsv_ns.tmp
    # copy output & remove second temporary file
rm .xmltocsv.tmp
mv .xmltocsv_ns.tmp .xmltocsv.tmp

delimeters=("." "," "@" "#" "$" "%" "^" "&" "*" "(" ")" "+" ";" ":" "?" "~" "|" "\`" "!" "-" "#" "'" "(" ")" "[" "]" "{" "}")
delimeter="$2" # forcing some delimeter (default: empty string)
    # looking for proper delimeter for sed command
if [ "$delimeter" = "" ]; then
    for i in "${delimeters[@]}" {a..z} {A..Z} {0..9}
    do
        echo "Checking delimeter: $i"
       if ! grep -q "$i" .xmltocsv.tmp 2>/dev/null; then #char does not exists
        echo "Selected $i as delimeter!"
        delimeter=$i
        break
       fi
    done
fi

if [ "$delimeter" = "" ]; then
    echo "Proper delimeter not found! Script needs to shutdown."

else

        # remove History tags
    sed -i -e 's'$delimeter'<History>'$delimeter'<!--<History>'$delimeter'g' .xmltocsv.tmp
    sed -i -e 's'$delimeter'</History>'$delimeter'</History>-->'$delimeter'g' .xmltocsv.tmp

        # null username case convert to empty value
    sed -i -e 's'$delimeter'<Key>UserName</Key> <Value/>'$delimeter'<Key>UserName</Key> <Value></Value>'$delimeter'g' .xmltocsv.tmp
        # open tag UserName
    sed -i -e 's'$delimeter'<String> <Key>UserName</Key> <Value>'$delimeter'<UserName>'$delimeter'g' .xmltocsv.tmp
        # null password case convert to empty value
    sed -i -e 's'$delimeter'<Value ProtectInMemory="True"/>'$delimeter'<Value ProtectInMemory="True"></Value>'$delimeter'g' .xmltocsv.tmp
        # close tag UserName, open tag Password
    sed -i -e 's'$delimeter'</Value> </String> <String> <Key>Password</Key> <Value ProtectInMemory="True">'$delimeter'</UserName><Password>'$delimeter'g' .xmltocsv.tmp
        # null URL case convert to empty value
    sed -i -e 's'$delimeter'<Key>URL</Key> <Value/>'$delimeter'<Key>URL</Key> <Value></Value>'$delimeter'g' .xmltocsv.tmp
        # close tag Password, open tag URL
    sed -i -e 's'$delimeter'</Value> </String> <String> <Key>URL</Key> <Value>'$delimeter'</Password><URL>'$delimeter'g' .xmltocsv.tmp
        # close tag URL
    sed -i -e 's'$delimeter'</Value> </String> <String> <Key>Notes</Key>'$delimeter'</URL> <String> <Key>Notes</Key>'$delimeter'g' .xmltocsv.tmp

        # generate csv output file from temporary file
    xml2csv --input ".xmltocsv.tmp" --output "$xmlFile.csv" --tag "Entry" --delimiter , --noheader --ignore Group Notes Name IsExpanded DefaultAutoTypeSequence EnableAutoType EnableSearching LastTopVisibleEntry UUID IconID ForegroundColor BackgroundColor OverrideURL Tags Times LastModificationTime CreationTime LastAccessTime ExpiryTime Expires UsageCount LocationChanged AutoType Enabled DataTransferObfuscation History String Key Value > /dev/null

        # check how many not needed commas are in output data
        # if any - there will be problem with quality of output file
    commas=$(grep -o , $xmlFile.csv | wc -l)
    lines=$(cat $xmlFile.csv | wc -l)
    lines=$(($lines * 2)) #two commas per line because three columns with data
    
    if [ $commas -ne $lines ]; then
        echo "Too many commas! Please check your XML data for commas and see warning no 2 in script. Quality of output CSV file can not be ensured."
    fi

        # set proper column oder (url, username, password)
        # using 5x hash to be almost sure about unique string
    awk -F, '{print $3,$1,$2}' OFS="#####" $xmlFile.csv > .xmltocsv.tmp #OFS is a delimeter at output
    mv .xmltocsv.tmp $xmlFile.csv

        # remove quotation marks (be careful to not remove chars from passwords!)
    sed -i -e 's'$delimeter'"#####"'$delimeter'\,'$delimeter'g' $xmlFile.csv # remove quotation marks between fields
    sed -i -e 's'$delimeter'"$'$delimeter''$delimeter'g' $xmlFile.csv # remove last char from each line
    sed -i -e 's'$delimeter'^"'$delimeter''$delimeter'g' $xmlFile.csv # remove first char from each line

        # fix escape chars that is output from xml2csv tool
        # xml2csv manual: Quotes within values can be escaped either doubling them ("" and '') [...]
    sed -i -e 's'$delimeter'""'$delimeter'"'$delimeter'g' $xmlFile.csv
    sed -i -e "s"$delimeter"''"$delimeter"'"$delimeter"g" $xmlFile.csv

        # change header of final csv file to meet Firefox requirements
    echo '# Generated by Password Exporter; Export format 1.0.4; Encrypted: false' | cat - $xmlFile.csv > .xmltocsv.tmp
    mv .xmltocsv.tmp $xmlFile.csv
    
        # removing lines where url or password are empty
    sed -i '' '/^,/d' $xmlFile.csv # line starting with comma so there is no url
    sed -i '' '/,$/d' $xmlFile.csv # line ending with comma so there is no password
    
        # check for http / https or ports
    if grep -q "http" $xmlFile.csv 2>/dev/null; then
        echo "Remove 'http' and 'https' prefixes from URLS!"
    fi
    
            # remove 4-digit ports in final csv file
    sed -i -e 's'$delimeter':....\,'$delimeter'\,'$delimeter'g' $xmlFile.csv
    
        # suggest some delimeters from ready csv file for the next time
    if [ "$3" = "suggest" ]; then
        for i in "${delimeters[@]}" {a..z} {A..Z} {0..9}
        do
           if ! grep -q "$i" $xmlFile.csv 2>/dev/null; then #char does not exists
            echo "Next time you can probably use $i as delimeter!"
           fi
        done
    fi

    echo "Finished! Plase see generated $xmlFile.csv file for results."

fi

    # remove temporary files
if [ -f .xmltocsv.tmp ]; then
    rm .xmltocsv.tmp
fi

if [ -f .xmltocsv.tmp-e ]; then
    rm .xmltocsv.tmp-e
fi

if [ -f $xmlFile.csv-e ]; then
    rm $xmlFile.csv-e
fi