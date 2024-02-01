#!/bin/bash
#apply execution permission via terminal running below line, navigate to the containing folder
#chmod +x menu.sh
#to run the script
#./menu.sh

echo "Choose a task:"
echo "0. List all MAG and Kozakura installed apps"
echo "1. List all installed apps"
echo "2. Capture log for a specific app"
echo "3. Capture log for a specific app"
echo "4. Perform another task"
echo "5. List MAG games and ask to uninstall or not"
echo "6. List MAG games and prompt to uninstall"

read -p "Enter your choice (0/1/2/3/4/5/6): " choice

case $choice in
  0)
    echo "Listing all MAG installed apps:"
    adb shell pm list packages | grep "maginteractive\|kozakura" 
    ;;
  1)
    echo "Listing all installed apps:"
    adb shell pm list packages
    ;;
  2)
    read -p "Enter the package name of the app: " packageName
    adb logcat "*:W" | grep "$packageName" > logcat.log
    echo "Log captured for $packageName. Check logcat.log"
    ;;
  3)
    read -p "Enter the package name of the app: " packageName
    read -p "Name of log: " logName
    adb logcat "*:W" | grep "$packageName" > /Users/chrispeters/Downloads/"$logName".log
    echo "Log captured for $packageName. Check "$logName".log"
    ;;
  4)
    echo "Performing another task..."
    # Add your custom task here
    ;;
  5)
   # List all apps with "test" in their package names
   echo "Listing all Test installed apps:"
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
    ;; 
  6)
    # List all apps with "testing" in their package names
    echo "Listing all installed MAG apps:"
    while IFS= read -r package; do
      echo "Found: $package"
      packages+=("$package")
    done < <(adb shell pm list packages | grep "maginteractive")

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
          sleep 2  # Add a delay between uninstallations
          adb shell pm uninstall "$package"
          sleep 4  # Add a delay between uninstallations
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
    ;;
  *)
    echo "Not a valid menu choice. Exiting."
    ;;
esac