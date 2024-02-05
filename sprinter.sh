#!/bin/bash

echo -e "\e[34m"
echo "############################################"
echo "#   ____ ___  ____ _ _  _ ___ ____ ____    #"
echo "#   [__  |__] |__/ | |\ |  |  |___ |__/    #"
echo "#   ___] |    |  \ | | \|  |  |___ |  \    #"
echo "#                                    WG    #"
echo "############################################"
echo -e "\e[0m"


read -p "Enter the IP range for scanning: " ip_range
masscan -p80 --rate 2000 --output-format json --output-filename masscan_output.json $ip_range

mapfile -t paths < dir.txt

print_with_color() {
    local status="$1"
    local message="$2"
    case "$status" in
        200)
            echo -e "\e[32m$message\e[0m"  # Green
            ;;
        *)
            echo "$message"  # Default, no color
            ;;
    esac
}

jq -r '.[] | .ip + " " + (.ports[0].port | tostring)' masscan_output.json | while read -r ip port; do
    echo -e "\e[34mIP: $ip:$port\e[0m"
    for path in "${paths[@]}"; do
        # Construct the URL
        url="http://$ip:$port/$path"
        
        # Display the directory being tested briefly
        echo -ne "TESTING [$url]...\r"
        sleep 0.1  # Brief pause to ensure visibility
        
        # Fetch the status code using curl with a 15-second timeout
        status=$(curl -m 5 --parallel-immediate -o /dev/null -s -w "%{http_code}" "$url")

        # Print the status and URL only if it's 200, 301, 302, or 303
        case "$status" in
            200)
                echo -e "TESTING [$url]"
                print_with_color "$status" "STATUS [$status]"
                echo ""  # Newline for clarity
                ;;
            *)
                # Clear the line
                echo -ne "\033[K"
                ;;
        esac
    done
    echo ""  # Newline for clarity between IPs
done
