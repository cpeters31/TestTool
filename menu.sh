#!/bin/bash
#apply execution permission via terminal running below line, navigate to the containing folder
#chmod +x menu.sh
#to run the script
#./menu.sh

#!/bin/bash

#Function to set userspath
userpath(){
user_home=$(eval echo "~")
last_word=$(echo "$user_home" | sed 's#.*/##')
echo "Log will be stored: /Users/${last_word}/Downloads/${logName}_${current_datetime}.log"
}

# Function to display the menu
show_menu() {
  clear
  echo "Choose a task:"
  echo "0. List connected device information"
  echo "1. List all MAG and Kozakura installed apps"
  echo "2. Capture log for a specific app"
  echo "3. Capture log for a specific app and search term"
  echo "4. Open Logging script"
  echo "5. List MAG games and ask to uninstall or not"
  echo "6. List MAG games and prompt to uninstall"
  echo "7. Record the phone screen for devices that don't have screen recording"
  echo "8. Exit"
}

#Function to add command to the logfile
commandused(){
    echo "Command: adb logcat \"*:W\" | grep \"$packageName\" > \"/Users/${last_word}/Downloads/${logName}_${current_datetime}.log\"" > "/Users/${last_word}/Downloads/${logName}_${current_datetime}.log"
    echo >> "/Users/${last_word}/Downloads/${logName}_${current_datetime}.log"  # Add a blank line
}

#Function for logcapture, asking for filename and search term,  appending the datetime to the logname
logger(){
    read -p "Enter search term: " packageName
    read -p "Log file name: " logName
    current_datetime=$(date +"%Y%m%d_%H%M%S")
    userpath
    adb logcat "*:W" | grep "$packageName" >> "/Users/${last_word}/Downloads/${logName}_${current_datetime}.log" 2>&1 &
    adb_pid=$!
}

#Function to cleanup and capture stuff when force ending log capture
cleanup() {
    if [ -n "$adb_pid" ] && [ "$adb_pid" -gt 0 ]; then
        echo -e "\nLog captured for $packageName. Check ${logName}_${current_datetime}.log"
        # Terminate the background process
        kill "$adb_pid"
    else
        echo $adb_pid
        echo "Log capture process not started or already terminated"
        read -p "Press Enter to continue..."
        clear
        show_menu
    fi
    exit 1
}

while true; do
show_menu

read -p "Enter your choice (0/1/2/3/4/5/6/7/8): " choice

case $choice in
  0)
    echo "Listing information on connected devices"

    get_readable_name() {
    case $1 in
        "SM-A136U1") echo "Galaxy A13 5G";;
        # Add more cases as needed
        *) echo "Unknown Device";;
    esac
    }

    devices=$(adb devices | grep -v "List" | awk '{print $1}')
    for device in $devices; do
    model=$(adb -s $device shell getprop ro.product.model)
    readable_name=$(get_readable_name "$model")

    echo "Device: $device"
    echo "  Model: $model"

    # Display the readable name only if it is known
    if [ "$readable_name" != "Unknown Device" ]; then
        echo "  Model Name: $readable_name"
    fi
    echo "  Manufacturer: $(adb -s $device shell getprop ro.product.manufacturer)"
    echo "  Android Version: $(adb -s $device shell getprop ro.build.version.release)"
    echo "  Screen Resolution: $(adb -s $device shell wm size)"
    echo "  Screen Density: $(adb -s $device shell wm density)"
    echo "  Total free memory: $(adb -s $device shell df | awk '/\/data/ { total += $4 } END { print "" total / 1024 / 1024 " MB" }')"
    echo "---"
    done
    read -p "Press Enter to continue..."
    ;;
  1)
    #echo "Listing all MAG installed apps:"
    #adb shell pm list packages | grep "maginteractive\|kozakura" 
    #done
    #;;
    # List all packages containing "maginteractive" or "kozakura"
    packages=$(adb shell pm list packages | grep -E "maginteractive|kozakura")

    # Count the number of packages
    num_packages=$(echo "$packages" | wc -l)
    echo "Installed games: "$num_packages

    # Loop through each package and retrieve its version
    for ((i = 1; i <= num_packages; i++)); do
    package=$(echo "$packages" | sed -n "${i}p")
    package_name=$(echo "$package" | cut -d ":" -f 2)
    version=$(adb shell dumpsys package "$package_name" | grep "versionName" | cut -d "=" -f 2)
    echo "Package: $package_name"
    echo "Version: $version"
    done
    read -p "Press Enter to continue..."
    ;;
  
  2)
    trap cleanup SIGINT

    logger
    commandused
    adb logcat "*:W" | grep "$packageName" > ${logName}.log
    wait "$adb_pid"
    cleanup
    ;;
  3)
    cleanup() {
      
    echo -e "\nLogs captured for $packageName. Check "${logName}_${current_datetime}".log"
    # Terminate the background process
    kill "$adb_pid"
    exit 1
    }

    trap cleanup SIGINT

    logger
    userpath
    # Log the command at the top of the file
    echo "Command: adb logcat \"*:W\" | grep \"$packageName\" > \"/Users/${last_word}/Downloads/${logName}_${current_datetime}.log\"" > "/Users/${last_word}/Downloads/${logName}_${current_datetime}.log"

    # Run adb logcat in the background and capture its process ID
    adb logcat "*:W" | grep "$packageName" >> "/Users/${last_word}/Downloads/${logName}_${current_datetime}.log" 2>&1 &
    adb_pid=$!

    # Wait for the background process to finish
    wait "$adb_pid"

    echo "Logs captured for $packageName. Check /Users/${last_word}/Downloads/${logName}_${current_datetime}.log"
    read -p "Press Enter to continue..."
    ;;
  4)
    clear
    echo "Opening the logging script..."
    # Run logging shell script
    source Logcapture/logcapture.sh
    read -p "Closed logging for now press enter to continue..."
    ;;
  5)
   # List all apps with "maginteractive" in their package names
   echo "Listing all MAG installed games:"
   adb shell pm list packages | grep "maginteractive"

   # Populate the packages array from the output of adb shell pm list packages
   packages=($(adb shell pm list packages | grep "maginteractive" | cut -d ":" -f 2 | tr -d "[:space:]"))

   # Loop through the array and prompt user for uninstallation
   for package in "${packages[@]}"; do
    read -p "Do you want to uninstall $package? (y/n): " answer
    if [ "$answer" == "y" ]; then
        echo "Uninstalling $package..."
        adb uninstall $package
    else
        echo "Skipping $package uninstallation."
    fi
    done
    read -p "Press Enter to continue..."
    ;; 
  6)
    # List all apps with "maginteractive" in their package names
    echo "Listing all installed MAG apps:"
    while IFS= read -r package; do
      echo "Found: $package"
      packages+=("$package")
    done < <(adb shell pm list packages | grep -E "maginteractive|kozakura")

    # Check if any packages were found
    if [ ${#packages[@]} -eq 0 ]; then
       echo "No installed MAG games found. Exiting."
       exit 0
    fi

    # Prompt user for uninstallation
    for package in "${packages[@]}"; do
       read -p "Do you want to uninstall $package? (y/n): " answer
       if [ "$answer" == "y" ]; then
          echo "Uninstalling $package..."
          sleep 5  # Add a delay between uninstallations
          adb shell pm uninstall "$package"
          sleep 8  # Add a delay between uninstallations
          # Check the result of uninstallation
          if [ $? -eq 0 ]; then
             echo "Uninstallation of $package successful."
          else
             echo "Error: Uninstallation of $package failed."
          fi
        else
          echo "Skipping $package uninstallation."
        fi
    done
    read -p "Uninstall checks complete press enter to continue..."
    ;;
  7)
    #for devices that don't have screen recording built it
    #record the screen and save to file on device using filename and date time
    current_datetime=$(date +"%Y%m%d_%H%M%S")
    read -p "Save the recording as: " logName
    adb shell screenrecord /mnt/sdcard/Download/${logName}_${current_datetime}.mp4
    read -p "Press Enter to continue..."
    ;;
  8)
    read -p "Exiting... press enter to continue"
    exit 1
    ;;
  *)
    echo "Not a valid menu choice."
    read -p "Press Enter to continue..."
    clear
    ;;
esac

done