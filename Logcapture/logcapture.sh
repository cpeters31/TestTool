#!/bin/bash
#apply execution permission via terminal running below line, navigate to the containing folder
#chmod +x logcapture.sh
#to run the script
#./logcapture.sh

# cleanup() {
#     #echo "Log capture interrupted. Exiting."
#     echo -e "\nLogs captured and saved to $output_file"
#     exit 1
# }

# trap cleanup SIGINT

# current_datetime=$(date +"%Y%m%d_%H%M%S")
# default_output_file="log_capture_${current_datetime}.txt"

# echo "Choose a logcat filter option:"
# echo "1. All Unity logs"
# echo "2. Unity warnings and errors"
# echo "3. Custom filter (provide your own pattern)"
# read -p "Enter the option number: " option

# case "$option" in
#     1)
#         filter="Unity"
#         ;;
#     2)
#         filter="(W|E) Unity"
#         ;;
#     3)
#         read -p "Enter your custom filter pattern: " custom_filter
#         filter="$custom_filter"
#         ;;
#     *)
#         echo "Invalid option. Exiting."
#         exit 1
#         ;;
# esac

# read -p "Enter the output file name " user_output_file

# if [ -z "$user_output_file" ]; then
#     default_output_file="log_capture_${current_datetime}.txt"
#     output_file="$default_output_file"
# else
#     output_file="${user_output_file}_${current_datetime}.txt"
# fi

# adb logcat | grep -E "$filter" > "Logcapture/$output_file.txt" 2>&1

#Attempt 2
#!/bin/bash

cleanup() {
    echo -e "\nLogs captured and saved to $output_file"
    # Kill the background process (adb logcat)
    kill "$logcat_pid"
    clear
    source menu.sh
    exit 1
}

trap cleanup SIGINT

devices=$(adb devices | grep -v "List" | awk '{print $1}')

# Check if there are no connected devices
if [ -z "$devices" ]; then
    echo "No devices found. Exiting."
    exit 1
fi

# If there is more than one device, prompt the user to choose one
if [ $(echo "$devices" | wc -l) -gt 1 ]; then
    echo "Multiple devices found. Please choose a device:"
    select device in $devices; do
        break
    done
else
    device="$devices"
fi

#gets the date and time
current_datetime=$(date +"%Y%m%d_%H%M%S")
#sets the model to be used for the log filename
model=$(adb -s $device shell getprop ro.product.model)
#sets a default name which is model and date time
default_output_file="${model}_${current_datetime}.txt"

#menu to display
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
        clear
        source menu.sh
        exit 1
        ;;
esac

read -p "Enter the output file name: " user_output_file

if [ -z "$user_output_file" ]; then
    default_output_file="${model}_${current_datetime}.txt"
    output_file="$default_output_file"
else
    output_file="${user_output_file}_${model}_${current_datetime}.txt"
fi

# Run adb logcat in the background and capture its process ID
adb logcat | grep -E "$filter" > "Logcapture/$output_file" 2>&1 &
logcat_pid=$!

# Wait for background process to finish
wait "$logcat_pid"

echo "Logs captured and saved to $output_file"
