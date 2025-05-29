# vim: set ft=make :

# Setup development environment with interactive menu
setup-dev-env component="":
    #!/usr/bin/bash
    set -e

    # Function to install nvm and pyenv
    install_brew_tools() {
        echo "📦 Installing nvm and pyenv via Homebrew..."
        brew install nvm pyenv
        echo "✅ nvm and pyenv installed successfully"

        # Configure nvm in shell files
        echo "⚙️  Configuring nvm and pyenv in shell files..."

        # Configure .zshrc
        if ! grep -q "NVM_DIR" "$HOME/.zshrc" 2>/dev/null; then
            printf '\n# NVM Configuration\n' >> "$HOME/.zshrc"
            printf 'export NVM_DIR="$HOME/.nvm"\n' >> "$HOME/.zshrc"
            printf '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && . "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"\n' >> "$HOME/.zshrc"
            printf '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"\n' >> "$HOME/.zshrc"
            printf '\n# PyEnv Configuration\n' >> "$HOME/.zshrc"
            printf 'export PYENV_ROOT="$HOME/.pyenv"\n' >> "$HOME/.zshrc"
            printf '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"\n' >> "$HOME/.zshrc"
            printf 'eval "$(pyenv init -)"\n' >> "$HOME/.zshrc"
            echo "✅ Added nvm and pyenv configuration to .zshrc"
        else
            echo "ℹ️  nvm/pyenv configuration already exists in .zshrc"
        fi

        # Configure .bashrc
        if ! grep -q "NVM_DIR" "$HOME/.bashrc" 2>/dev/null; then
            printf '\n# NVM Configuration\n' >> "$HOME/.bashrc"
            printf 'export NVM_DIR="$HOME/.nvm"\n' >> "$HOME/.bashrc"
            printf '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && . "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"\n' >> "$HOME/.bashrc"
            printf '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"\n' >> "$HOME/.bashrc"
            printf '\n# PyEnv Configuration\n' >> "$HOME/.bashrc"
            printf 'export PYENV_ROOT="$HOME/.pyenv"\n' >> "$HOME/.bashrc"
            printf '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"\n' >> "$HOME/.bashrc"
            printf 'eval "$(pyenv init -)"\n' >> "$HOME/.bashrc"
            echo "✅ Added nvm and pyenv configuration to .bashrc"
        else
            echo "ℹ️  nvm/pyenv configuration already exists in .bashrc"
        fi
    }

    # Function to install Flutter
    install_flutter() {
        echo "🐦 Setting up Flutter SDK..."

        # Create Development folder if it doesn't exist
        mkdir -p "$HOME/Development"
        cd "$HOME/Development"

        if [ ! -d "flutter" ]; then
            echo "📥 Downloading Flutter SDK..."
            wget -O flutter_linux.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.5-stable.tar.xz
            tar xf flutter_linux.tar.xz
            rm flutter_linux.tar.xz
            echo "✅ Flutter SDK installed successfully"
        else
            echo "ℹ️  Flutter already exists, skipping download"
        fi

        # Configure Flutter in shell files
        echo "⚙️  Configuring Flutter in shell files..."

        # Configure .zshrc
        if ! grep -q "Development/flutter/bin" "$HOME/.zshrc" 2>/dev/null; then
            printf '\n# Flutter Configuration\n' >> "$HOME/.zshrc"
            printf 'export PATH="$HOME/Development/flutter/bin:$PATH"\n' >> "$HOME/.zshrc"
            echo "✅ Added Flutter configuration to .zshrc"
        else
            echo "ℹ️  Flutter configuration already exists in .zshrc"
        fi

        # Configure .bashrc
        if ! grep -q "Development/flutter/bin" "$HOME/.bashrc" 2>/dev/null; then
            printf '\n# Flutter Configuration\n' >> "$HOME/.bashrc"
            printf 'export PATH="$HOME/Development/flutter/bin:$PATH"\n' >> "$HOME/.bashrc"
            echo "✅ Added Flutter configuration to .bashrc"
        else
            echo "ℹ️  Flutter configuration already exists in .bashrc"
        fi
    }

    # Function to install Android Studio
    install_android_studio() {
        echo "🤖 Setting up Android Studio..."

        # Create Development folder if it doesn't exist
        mkdir -p "$HOME/Development"

        if [ ! -d "$HOME/Development/android-studio" ]; then
            echo "📥 Downloading Android Studio..."
            cd "$HOME/Development"

            wget -O android-studio.tar.gz "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.28/android-studio-2023.1.1.28-linux.tar.gz"
            echo "📦 Extracting Android Studio..."
            tar -xzf android-studio.tar.gz
            rm android-studio.tar.gz

            chmod +x "$HOME/Development/android-studio/bin/studio.sh"
            echo "✅ Android Studio installed successfully"

            echo "🚀 Launching Android Studio for initial setup..."
            "$HOME/Development/android-studio/bin/studio.sh" &
        else
            echo "ℹ️  Android Studio already exists"
            echo "🚀 Launching existing Android Studio..."
            "$HOME/Development/android-studio/bin/studio.sh" &
        fi
    }

    # Function to install everything
    install_everything() {
        echo "🚀 Installing complete development environment..."
        install_brew_tools
        install_flutter
        install_android_studio
        show_completion_message
    }

    # Function to show completion message
    show_completion_message() {
        echo ""
        echo "🎉 Installation complete!"
        echo ""
        echo "📝 Next steps:"
        echo "1. Restart your terminal or run: source ~/.zshrc (or ~/.bashrc)"
        echo "2. Complete Android Studio setup wizard"
        echo "3. Run 'flutter doctor' to verify Flutter installation"
        echo "4. Install Node.js with: nvm install --lts"
        echo "5. Install Python with: pyenv install 3.11.0 && pyenv global 3.11.0"
        echo ""
        echo "📍 Installation locations:"
        echo "• Flutter: $HOME/Development/flutter"
        echo "• Android Studio: $HOME/Development/android-studio"
    }

    # Check if gum is available for menu
    if command -v gum >/dev/null 2>&1; then
        USE_GUM=true
    else
        USE_GUM=false
        echo "💡 Install 'gum' for better interactive menus: brew install gum"
    fi

    # Display menu or use provided component
    if [ -n "{{ component }}" ]; then
        CHOICE="{{ component }}"
    else
        echo ""
        echo "🛠️  Development Environment Setup"
        echo "================================"

        if [ "$USE_GUM" = true ]; then
            CHOICE=$(gum choose \
                "Complete Setup (Everything)" \
                "Homebrew Tools (nvm + pyenv)" \
                "Flutter SDK" \
                "Android Studio" \
                "Exit")
        else
            echo ""
            echo "Select an option:"
            echo "1) Complete Setup (Everything)"
            echo "2) Homebrew Tools (nvm + pyenv)"
            echo "3) Flutter SDK"
            echo "4) Android Studio"
            echo "5) Exit"
            echo ""
            read -p "Enter your choice (1-5): " choice_num

            case $choice_num in
                1) CHOICE="Complete Setup (Everything)" ;;
                2) CHOICE="Homebrew Tools (nvm + pyenv)" ;;
                3) CHOICE="Flutter SDK" ;;
                4) CHOICE="Android Studio" ;;
                5) CHOICE="Exit" ;;
                *) echo "Invalid choice"; exit 1 ;;
            esac
        fi
    fi

    # Exit early if user chose to exit
    [ "$CHOICE" = "Exit" ] && { echo "👋 Exiting..."; exit 0; }

    # Process user choice
    case "$CHOICE" in
        "Complete Setup (Everything)") 
            install_everything 
            ;;
        "Homebrew Tools (nvm + pyenv)") 
            install_brew_tools 
            ;;
        "Flutter SDK") 
            install_flutter 
            ;;
        "Android Studio") 
            install_android_studio 
            ;;
        *) 
            echo "❌ Invalid choice" 
            exit 1 
            ;;
    esac

    echo ""
    echo "✨ Task completed successfully!" 
