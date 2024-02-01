#!/bin/bash
#apply execution permission via terminal running below line, navigate to the containing folder
#chmod +x menu.sh
#to run the script
#./logcapture.sh

echo "Choose a logcat filter option:"
echo "1. All Unity logs"
echo "2. Unity warnings and errors"
echo "3. Custom filter (provide your own pattern)"
read -p "Enter the option number: " option

case "$option" in
    1)
        filter="Unity"
        ;;
    2)
        filter="(W|E) Unity"
        ;;
    3)
        read -p "Enter your custom filter pattern: " custom_filter
        filter="$custom_filter"
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

read -p "Enter the output file name: " output_file

adb logcat | grep -E "$filter" > "$output_file"

echo "Logs captured and saved to $output_file"