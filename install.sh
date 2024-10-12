#!/bin/bash

# Function to ask a question with a default answer of yes
ask_yes_no() {
    question=$1
    default="y"
    read -p "$question (Y/n): " answer
    answer=${answer:-$default}
    echo $answer
}

# Ask all installation options first
install_nginx=$(ask_yes_no "Do you want to install NGINX?")
install_node=$(ask_yes_no "Do you want to install Node.js and npm?")
install_mongodb=$(ask_yes_no "Do you want to install MongoDB?")
install_mysql=$(ask_yes_no "Do you want to install MySQL?")
install_sysbench=$(ask_yes_no "Do you want to install Sysbench?")
install_speedtest=$(ask_yes_no "Do you want to install Speedtest-cli?")
install_git=$(ask_yes_no "Do you want to install Git?")
install_conda=$(ask_yes_no "Do you want to install Miniconda?")
install_pm2=$(ask_yes_no "Do you want to install PM2?")
run_git_config=$(ask_yes_no "Do you want to clone and run the git-config script?")

# NGINX specific setup
if [ "$install_nginx" == "y" ]; then
    remove_nginx_default=$(ask_yes_no "Do you want to remove the default NGINX site?")
    create_proxy=$(ask_yes_no "Do you want to create an NGINX reverse proxy?")
    if [ "$create_proxy" == "y" ]; then
        echo "Enter the URL to proxy (e.g., http://google.com):"
        read proxy_url
    fi
fi

# Ask about starting services and testing services
start_services=$(ask_yes_no "Do you want to start all installed services?")
test_services=$(ask_yes_no "Do you want to test all services?")

# After all questions, run the installation process

# Update system
sudo apt update && sudo apt upgrade -y

# Install NGINX
if [ "$install_nginx" == "y" ]; then
    sudo apt install -y nginx
fi

# Install Node.js and npm
if [ "$install_node" == "y" ]; then
    sudo apt install -y nodejs npm
fi

# Install MongoDB
if [ "$install_mongodb" == "y" ]; then
    sudo apt install -y mongodb
fi

# Install MySQL
if [ "$install_mysql" == "y" ]; then
    sudo apt install -y mysql-server
fi

# Install Sysbench
if [ "$install_sysbench" == "y" ]; then
    sudo apt install -y sysbench
fi

# Install Speedtest-cli
if [ "$install_speedtest" == "y" ]; then
    sudo apt install -y speedtest-cli
fi

# Install Git
if [ "$install_git" == "y" ]; then
    sudo apt install -y git
fi

# Install Miniconda
if [ "$install_conda" == "y" ]; then
    echo "Installing Miniconda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
    bash ~/miniconda.sh -b -p $HOME/miniconda
    rm ~/miniconda.sh
    export PATH="$HOME/miniconda/bin:$PATH"
    conda init
fi

# Install PM2
if [ "$install_pm2" == "y" ]; then
    sudo npm install pm2 -g
fi

# Clone and run Git configuration script
if [ "$run_git_config" == "y" ]; then
    echo "Cloning and running Git configuration script..."
    git clone https://github.com/uzaircs/git-config.git
    cd git-config
    chmod +x configure-git.sh
    ./configure-git.sh
    cd ..
fi

# NGINX configuration if NGINX is installed
if [ "$install_nginx" == "y" ]; then
    # Remove default NGINX site
    if [ "$remove_nginx_default" == "y" ]; then
        echo "Removing default NGINX site..."
        sudo rm /etc/nginx/sites-enabled/default
    fi

    # Create NGINX reverse proxy
    if [ "$create_proxy" == "y" ]; then
        echo "Setting up NGINX reverse proxy to $proxy_url..."
        cat <<EOL | sudo tee /etc/nginx/sites-available/reverse-proxy
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass $proxy_url;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
        sudo ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/reverse-proxy
        sudo systemctl enable nginx
    fi
fi

# Start all services
if [ "$start_services" == "y" ]; then
    echo "Starting all services..."
    sudo systemctl start nginx
    sudo systemctl start mongodb
    sudo systemctl start mysql
fi

# Test services
if [ "$test_services" == "y" ]; then
    # Test NGINX
    if [ "$install_nginx" == "y" ]; then
        echo "Testing NGINX..."
        if systemctl status nginx | grep "active (running)" > /dev/null; then
            echo "NGINX is running successfully."
        else
            echo "NGINX is not running."
        fi
    fi

    # Test MongoDB
    if [ "$install_mongodb" == "y" ]; then
        echo "Testing MongoDB..."
        if systemctl status mongodb | grep "active (running)" > /dev/null; then
            echo "MongoDB is running successfully."
        else
            echo "MongoDB is not running."
        fi
    fi

    # Test MySQL
    if [ "$install_mysql" == "y" ]; then
        echo "Testing MySQL..."
        if systemctl status mysql | grep "active (running)" > /dev/null; then
            echo "MySQL is running successfully."
        else
            echo "MySQL is not running."
        fi
    fi

    # Test Node.js
    if [ "$install_node" == "y" ]; then
        echo "Testing Node.js..."
        if node -v > /dev/null; then
            echo "Node.js is installed successfully. Version: $(node -v)"
        else
            echo "Node.js is not installed correctly."
        fi
    fi

    # Test PM2
    if [ "$install_pm2" == "y" ]; then
        echo "Testing PM2..."
        if pm2 -v > /dev/null; then
            echo "PM2 is installed successfully. Version: $(pm2 -v)"
        else
            echo "PM2 is not installed correctly."
        fi
    fi

    # Test Speedtest-cli
    if [ "$install_speedtest" == "y" ]; then
        echo "Testing Speedtest-cli..."
        if speedtest-cli > /dev/null; then
            echo "Speedtest-cli is working correctly."
        else
            echo "Speedtest-cli is not working."
        fi
    fi
fi

echo "All tasks completed."
