#!/bin/bash

# auto_install.sh - Automated installation script for man-pages-ja
# Execute make config and make install without requiring stdin input

set -e  # Exit on error

# Check if expect is installed
if ! command -v expect &> /dev/null; then
    echo "Error: expect is not installed, Please install expect with the following command."
    exit 1
fi

# Automatic execution of make config
expect << 'EOF' > /dev/null 2>&1
#!/usr/bin/expect -f
set timeout 60

# Execute make config
spawn make config

expect {
    "Install directory*?: " {
        send "\r"
        exp_continue
    }
    "compress manual with.." {
        expect "select*: "
        send "1\r"
        exp_continue
    }
    "uname of page owner*?: " {
        send "\r"
        exp_continue
    }
    "group of page owner*?: " {
        send "\r"
        exp_continue
    }
    "All OK?*: " {
        send "c\r"
        exp_continue
    }
    "*\]*?: " {
        # Use default values for all package selections
        send "\r"
        exp_continue
    }
    "Which to install?*: " {
        # Use default values for all conflict resolutions
        send "\r"
        exp_continue
    }
    "creating installation script" {
        # Wait for script generation completion
        expect eof
    }
    eof {
        # Normal exit
    }
    timeout {
        puts "Error: Timeout occurred."
        exit 1
    }
}

# Wait for expect process to finish
wait
EOF

# Check expect exit status
if [ $? -ne 0 ]; then
    echo "Error: make config failed."
    exit 1
fi

# Check if installman.sh was created
if [ ! -f "installman.sh" ]; then
    echo "Error: installman.sh was not created."
    exit 1
fi

# Execute make install
if ! make install > /dev/null 2>&1; then
    echo "Error: make install failed."
    exit 1
fi
