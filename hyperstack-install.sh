# Read SSH command from user input
echo "Enter the IP address of the server:"
read ip

username="ubuntu"
key_file="$HOME/.ssh/personal_id_ed25519"
runpod_key_file="$HOME/.ssh/runpod_id_ed25519"

run_ssh="ssh $username@$ip -i $key_file -o StrictHostKeyChecking=no"

echo "IP: $ip"
echo "USERNAME: $username"
echo "KEY FILE: $key_file"
echo "RUNPOD KEY FILE: $runpod_key_file"
# Copy the private key to the remote server
echo "Copying private key to remote server..."
scp -i $runpod_key_file $runpod_key_file $username@$ip:~/.ssh/id_ed25519
echo "Key copied successfully."

# Set proper permissions for the key on the remote server
echo "Setting proper permissions for the key on the remote server..."
eval "$run_ssh 'chmod 600 ~/.ssh/id_ed25519'"
echo "Permissions set successfully."

# Copy the public key to the remote server
echo "Copying public key to remote server..."
scp -i $runpod_key_file "${runpod_key_file}.pub" $username@$ip:~/.ssh/id_ed25519.pub
echo "Public key copied successfully."

# Set proper permissions for the public key on the remote server
echo "Setting proper permissions for the public key on the remote server..."
eval "$run_ssh 'chmod 644 ~/.ssh/id_ed25519.pub'"
echo "Permissions set successfully."

# SSH into the remote server and run commands
echo "Connecting to remote server for initial setup..."
eval "$run_ssh" << 'EOF'
    set -e
    echo "connected to remote server"
    echo "Setting up git config"
    git config --global user.email "aidando73@gmail.com"
    git config --global user.name "Aidan Do"
    git config --global core.editor "vim"
    git config --global init.defaultBranch main

    echo "Install direnv"
    sudo apt install -y software-properties-common
    sudo add-apt-repository universe
    sudo apt update
    sudo apt install -y direnv
    mkdir -p ~/.config/direnv
    echo -e "[global]\nload_dotenv=true" > ~/.config/direnv/direnv.toml
    echo "Installing conda"
    mkdir -p ~/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
    rm ~/miniconda3/miniconda.sh
    sudo apt install -y tmux
    
    sudo apt install -y vim
    sudo apt install -y git-lfs
    git lfs install
    
EOF
echo "Commands executed successfully."

# SSH into the remote server again
echo "SSH command:"
echo "ssh $username@$ip -p $port -i $key_file"