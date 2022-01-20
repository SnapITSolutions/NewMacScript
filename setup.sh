#!/usr/bin/env bash
# shellcheck disable=SC1091

# Apps, fonts, and other items that should install automatically for you

title="SnapIT MacOS Software Installer"

shopt -s extglob # turn on extended pattern matching

installAndroid=0
installDataScience=0
installDatabase=0
installDevOps=0
installPrototyping=0
installJava=0
installReact=0
installShell=0

# Initialize package lists to install from Homebrew
# Note: rvm and nvm are not Homebrew packages, but triggers to install those apps using their online installers

# base packages that need to be installed before prompting for other packages
baseInstall=(
    dialog
    dockutil
    jq
    wget
    subversion
)

# Always install these packages
alwaysInstall=(
    autoconf
    automake
    coreutils
    findutils
    moreutils
    gawk
    gnu-sed
    grep
    gzip
    unzip
    git
    gnupg
    fontconfig
    python@3.9
    openssh
    homebrew/cask/iterm2
    homebrew/cask/zoom
)

# Packages for Ruby/Rails developers
rubyInstall=(
    libyaml
    zlib
    rvm
    homebrew/cask/postman
)

# Packages for React developers
reactInstall=(
    nvm
    node
    yarn
    homebrew/cask/docker
    homebrew/cask/postman
)

# packages for Java developers
javaInstall=(
    homebrew/cask/oracle-jdk
    homebrew/cask/oracle-jdk-javadoc
    homebrew/cask/jdk-mission-control
    homebrew/cask/postman
)

# packages for Android developers
androidInstall=(
    kotlin
    homebrew/cask/android-file-transfer
    homebrew/cask/android-platform-tools
    homebrew/cask/android-studio
)

# packages for Data Science developers
dataScienceInstall=(
    homebrew/core/r
    homebrew/cask/jupyterlab
    homebrew/cask/rstudio
)

# packages for devOps
devOpsInstall=(
    nvm
    node
    yarn
)

# packages for shell scripting
shellInstall=(
    bash
    bash-completion
    homebrew/cask/powershell
)

# packages for database management
databaseInstall=(
    mysql
    sqlite
    homebrew/cask/mysqlworkbench
    homebrew/cask/db-browser-for-sqlite
)

# packages for prototyping
prototypingInstall=(
    homebrew/cask/gimp
    imagemagick
    homebrew/cask/inkscape
    homebrew/cask/miro
    homebrew/cask/pencil
)

# editor and IDE packages (filled in later)
editorInstall=()

# browser packages (filled in later)
browserInstall=()

# GUI packages for git (filled in later)
gitUiInstall=()

# optional packages (filled in later)
optionalInstall=()

# items to add to the Dock
dockItems=(
    "iTerm"
    "Postman"
    "Android Studio"
    "JupyterLab"
    "RStudio"
    "Atom"
    "IntelliJ IDEA CE"
    "Eclipse Java"
    "MacDown"
    "MacVim"
    "PyCharm CE"
    "Visual Studio Code"
    "Firefox"
    "Google Chrome"
    "Fork"
    "GitKraken"
    "MySQLWorkbench"
    "DB Browser for SQLite"
)

# Fonts to install (mostly monospaced)
fontInstall=(
    font-anonymous-pro
    font-cascadia-code
    font-cascadia-code-pl
    font-cascadia-mono
    font-cascadia-mono-pl
    font-courier-prime
    font-courier-prime-code
    font-courier-prime-medium-and-semi-bold
    font-courier-prime-sans
    font-dm-mono
    font-dm-sans
    font-dm-serif-display
    font-dm-serif-text
    font-fantasque-sans-mono
    font-fira-code
    font-fira-mono
    font-go
    font-hack
    font-inconsolata
    font-jetbrains-mono
    font-juliamono
    font-league-gothic
    font-league-mono
    font-league-spartan
    font-monoid
    font-mononoki
    font-montserrat
    font-montserrat-alternates
    font-noto-sans
    font-noto-sans-mono
    font-noto-serif
    font-oxygen
    font-oxygen-mono
    font-pt-mono
    font-pt-sans
    font-pt-sans-caption
    font-pt-sans-narrow
    font-pt-serif
    font-pt-serif-caption
    font-recursive-code
    font-roboto
    font-roboto-mono
    font-roboto-slab
    font-source-code-pro
    font-source-sans-pro
    font-source-serif-pro
    font-ubuntu
    font-ubuntu-condensed
    font-ubuntu-mono
)

promptToStart() {
    cat <<EOF

$title

This script will prompt for your password several times, as it installs
applications which require admin access.

EOF
    read -rp "Are you ready to begin the installation process? [y/n]: " yn
    if [[ ${yn:0:1} != "y" && ${yn:0:1} != "Y" ]]
    then
        echo "Installer canceled!"
        exit 1
    fi
}

makeTempFiles() {
    dialogtmpfile=$(mktemp -q 2>/dev/null) || dialogtmpfile=/tmp/dialog$$
    vstmpfile=$(mktemp -q 2>/dev/null) || vstmpfile=/tmp/vscodeextensions$$
        fontdir=$(mktemp -d -q 2>/dev/null) || {
        fontdir=/tmp/font$$
        mkdir -p $fontdir
    }
    trap 'rm -rf $dialogtmpfile $vstmpfile $fontdir; return 1' SIGHUP SIGINT SIGTRAP SIGTERM
}

parseGitConfig() {
    if [ -f "$HOME"/.gitconfig ]
    then
        name=$(sed -nr "/^\[user\]/ { :l /^[ \t]*name[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" ~/.gitconfig)
        email=$(sed -nr "/^\[user\]/ { :l /^[ \t]*email[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" ~/.gitconfig)
        userId=$(sed -nr "/^\[github\]/ { :l /^[ \t]*user[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" ~/.gitconfig)
    fi
}

initXCode () {
    if [[ ! -d "$('xcode-select' -print-path 2>/dev/null)" ]]
    then
        echo "Initializing XCode Command Line Tools"
        xcode-select --install 2>/dev/null
        # wait until XCode Command Line Tools are installed
        until xcode-select --print-path &> /dev/null
        do
            sleep 5
        done
    fi
}

initHomebrew() {
    if type -P brew &> /dev/null
    then
        echo "Homebrew already installed!"
        echo "Updating Homebrew..."
        brew update -q
        brew upgrade -q
    else
        echo "Installing Homebrew..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        brew doctor
        brew update -q
        echo "Homebrew installed successfully"
    fi
}

tapHomebrew() {
    echo "Setting up Homebrew taps..."
    taps=(
        homebrew/cask
        homebrew/cask-drivers
        homebrew/cask-fonts
    )
    for tap in "${taps[@]}"
    do
        brew tap | grep -q "^${tap}$" || brew tap "${tap}"
    done
}

cleanupHomebrew() {
    echo "Cleaning up Homebrew..."
    brew cleanup -q
}

installRuby() {
    type -P rvm &> /dev/null || {
        echo "Installing RVM..."
        touch "$HOME/.bashrc"
        touch "$HOME/.zshrc"
        command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
        command curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
        command df -hcurl -sSL https://get.rvm.io | bash -s stable --ruby --rails
        # TODO add rvm config to .bashrc and .zshrc
# [ -s "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"
    }
}

installNvm() {
    test -d "$HOME/.nvm" || {
        echo "Installing NVM..."
        # The following scripts are needed for the nvm installer
        touch "$HOME/.bashrc"
        touch "$HOME/.zshrc"
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh)"
        # TODO add nvm config to .bashrc and .zshrc
#NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
#export NVM_DIR
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    }
}

checkInstall() {
    bash -c "brew list --formula --versions; brew list --cask --versions" | grep -q "^$1 " &> /dev/null
}

installApp() {
    pkg="$1"
    if [[ $pkg == nvm ]]
    then
        installNvm
    elif [[ $pkg == rvm ]]
    then
        installRuby
    else
        checkInstall "$pkg" || {
            echo "Installing $pkg..."
            brew install -q "$pkg"
        }
    fi
}

installBasePackages() {
    echo "Installing base packages..."
    for pkg in "${baseInstall[@]}"
    do
        installApp "$pkg"
    done
}

installPackages() {
    echo "Installing packages..."
    for pkg in "${alwaysInstall[@]}"
    do
        installApp "$pkg"
    done
    if [[ $installRuby -eq 1 ]]
    then
        for pkg in "${rubyInstall[@]}"
        do
            installApp "$pkg"
        done
    fi
    if [[ $installReact -eq 1 ]]
    then
        for pkg in "${reactInstall[@]}"
        do
            installApp "$pkg"
        done
    fi
    if [[ $installJava -eq 1 ]]
    then
        for pkg in "${javaInstall[@]}"
        do
            installApp "$pkg"
        done
    fi
    if [[ $installAndroid -eq 1 ]]
    then
        for pkg in "${androidInstall[@]}"
        do
            installApp "$pkg"
        done
    fi
    if [[ $installDataScience -eq 1 ]]
    then
        for pkg in "${dataScienceInstall[@]}"
        do
            installApp "$pkg"
        done
    fi
    if [[ $installDevOps -eq 1 ]]
    then
        for pkg in "${devOpsInstall[@]}"
        do
            installApp "$pkg"
        done
    fi
    if [[ $installShell -eq 1 ]]
    then
        for pkg in "${shellInstall[@]}"
        do
            installApp "$pkg"
        done
    fi
    if [[ $installDatabase -eq 1 ]]
    then
        for pkg in "${databaseInstall[@]}"
        do
            installApp "$pkg"
        done
    fi
    if [[ $installPrototyping -eq 1 ]]
    then
        for pkg in "${prototypingInstall[@]}"
        do
            installApp "$pkg"
        done
    fi
    for pkg in "${editorInstall[@]}"
    do
        installApp "$pkg"
    done
    for pkg in "${browserInstall[@]}"
    do
        installApp "$pkg"
    done
    for pkg in "${gitUiInstall[@]}"
    do
        installApp "$pkg"
    done
    for pkg in "${optionalInstall[@]}"
    do
        installApp "$pkg"
    done
}

startServices() {
    if [[ $installDatabase -eq 1 ]]
    then
        echo "Starting MySQL service..."
        brew services start mysql
    fi
}

installFonts() {
    echo "Installing fonts..."
    for font in "${fontInstall[@]}"
    do
        checkInstall "$font" || {
            echo "Installing font: $font..."
            brew install -q "$font"
        }
    done

    # Install fonts not available via Homebrew
    if [ ! -f ~/Library/Fonts/DroidSansMono.ttf ]
    then
        echo "Installing DroidSansMono..."
        wget -q -O "$fontdir"/DroidSansMono.ttf \
            https://github.com/RPi-Distro/fonts-android/raw/master/DroidSansMono.ttf
        cp -av "$fontdir"/DroidSansMono.ttf ~/Library/Fonts/
    fi
    if [ ! -f ~/Library/Fonts/DroidSansMonoDotted.ttf ]
    then
        echo "Installing DroidSansMonoDotted..."
        wget -q -O "$fontdir"/DroidSansMonoDotted.ttf \
            https://github.com/AlbertoDorado/droid-sans-mono-zeromod/raw/master/DroidSansMonoDotted.ttf
        cp -av "$fontdir"/DroidSansMonoDotted.ttf ~/Library/Fonts/
    fi
    if [ ! -f ~/Library/Fonts/DroidSansMonoSlashed.ttf ]
    then
        echo "Installing DroidSansMonoSlashed..."
        wget -q -O "$fontdir"/DroidSansMonoSlashed.ttf \
            https://github.com/AlbertoDorado/droid-sans-mono-zeromod/raw/master/DroidSansMonoSlashed.ttf
        cp -av "$fontdir"/DroidSansMonoSlashed.ttf ~/Library/Fonts/
    fi

    fc-cache # rebuild the font cache
}

detectVSCode () {
    # first check the usual place for MacOS applications
    if [ -d "/Applications/Visual Studio Code.app" ]
    then
        code="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    # then check to see if the application in the path
    elif [ -x "$(command -v code)" ]
    then
        code="$(command -v code)"
    # finally, check to see if the open source version is installed in the path
    elif [ -x "$(command -v codium)" ]
    then
        code="$(command -v codium)"
    else
        echo "Unable to detect VS Code"
        return 1
    fi
    (( installed=0 ))
    "$code" --list-extensions > "${vstmpfile}" 2>&1
    return 0
}

installVSCodeExtension () {
    ext=$1
    grep -q "$ext" "${vstmpfile}" &>/dev/null || {
        echo "Installing VS Code Extension: $ext"
        "$code" --install-extension "$ext" > /dev/null
        (( installed++ ))
    }
}

installAllVSCodeExtensions () {
    # Install Visual Studio Code/codium extensions
    detectVSCode && {
        echo "Installing VS Code Extensions..."
        # Common Tools
        installVSCodeExtension ms-azuretools.vscode-docker # Docker
        installVSCodeExtension mikestead.dotenv # DotENV
        installVSCodeExtension ms-vsliveshare.vsliveshare # Live Share
        installVSCodeExtension redhat.vscode-yaml # YAML
        installVSCodeExtension DotJoshJohnson.xml # XML Tools
        installVSCodeExtension fnando.linter # Lint all the code
        installVSCodeExtension VisualStudioExptTeam.vscodeintellicode # Visual Studio Intellicode
        installVSCodeExtension eamodio.gitlens # Git Lens

        # Visualization Extensions
        # installVSCodeExtension CoenraadS.bracket-pair-colorizer-2 # Bracket Pair Colorizer 2 - deprecated
        installVSCodeExtension oderwat.indent-rainbow # Indent Rainbow
        installVSCodeExtension ybaumes.highlight-trailing-white-spaces # Highlight Trailing White Spaces
        installVSCodeExtension aaron-bond.better-comments # Better Comments
        installVSCodeExtension wayou.vscode-todo-highlight # TO DO highlight
        installVSCodeExtension Gruntfuggly.todo-tree # TO DO tree in explorer pane
        installVSCodeExtension ExodiusStudios.comment-anchors # Comment anchors

        # Text Manipulation Extensions
        installVSCodeExtension wmaurer.change-case # Change Case
        installVSCodeExtension Tyriar.sort-lines # Sort Lines
        installVSCodeExtension dakara.transformer # Text Transformer

        # JSON Extensions
        installVSCodeExtension renatorodrigues.json-to-js # JSON to JS converter
        installVSCodeExtension eriklynd.json-tools # JSON Tools

        # Markdown extensions
        installVSCodeExtension yzhang.markdown-all-in-one # Markdown All in One
        installVSCodeExtension DavidAnson.vscode-markdownlint # Markdown Lint

        # Diff extensions
        installVSCodeExtension rafaelmaiolla.diff # diff syntax highlighting
        installVSCodeExtension fabiospampinato.vscode-diff # diff file comparator

        # Miscellaneous Extensions
        installVSCodeExtension johnpapa.vscode-peacock # Peacock
        installVSCodeExtension christian-kohler.path-intellisense # Path Intellisense
        installVSCodeExtension ionutvmi.path-autocomplete # Path Autocomplete
        installVSCodeExtension techer.open-in-browser # Open in Browser

        # Ruby / Rails extensions
        if [[ $installRuby -eq 1 ]]
        then
            installVSCodeExtension rebornix.ruby # Ruby
            installVSCodeExtension wingrunr21.vscode-ruby # VSCode Ruby
            installVSCodeExtension castwide.solargraph # Ruby Solargraph
            installVSCodeExtension kaiwood.endwise # endwise
            installVSCodeExtension ninoseki.vscode-gem-lens # Gem Lens
            installVSCodeExtension karunamurti.haml # HAML
        fi

        # React/JS Extensions
        if [[ $installReact -eq 1 ]]
        then
            installVSCodeExtension dbaeumer.vscode-eslint # ESLint
            installVSCodeExtension dsznajder.es7-react-js-snippets # ES7 Snippets
            installVSCodeExtension msjsdiag.debugger-for-chrome # Debugger for Chrome
            installVSCodeExtension firefox-devtools.vscode-firefox-debug # Debugger for Firefox
            installVSCodeExtension burkeholland.simple-react-snippets # Simple React Snippets
        fi

        # Java Extensions
        if [[ $installJava -eq 1 ]]
        then
            installVSCodeExtension vscjava.vscode-java-pack # Java Extension Pack
            installVSCodeExtension redhat.java # Language Support for Java
            installVSCodeExtension vscjava.vscode-maven # Maven for Java
            installVSCodeExtension vscjava.vscode-java-debug # Debugger for Java
            installVSCodeExtension vscjava.vscode-java-dependency # Dependency Viewer for Java
            installVSCodeExtension vscjava.vscode-java-test # Java Test Runner
        fi

        # Kotlin Extensions
        if [[ $installAndroid -eq 1 ]]
        then
            installVSCodeExtension sethjones.kotlin-on-vscode # Kotlin Extension Pack
            installVSCodeExtension mathiasfrohlich.Kotlin # Kotlin Extension
            installVSCodeExtension fwcd.kotlin # Kotlin IDE
            installVSCodeExtension formulahendry.code-runner # Code Runner
            installVSCodeExtension vscjava.vscode-gradle # Gradle Tasks
            installVSCodeExtension naco-siren.gradle-language # Gradle Language Support
            installVSCodeExtension esafirm.kotlin-formatter # Kotlin Formatter using ktlint
        fi

        # Data Science Extensions
        if [[ $installDataScience -eq 1 ]]
        then
            installVSCodeExtension ms-python.python # Python Extension
            installVSCodeExtension ms-python.vscode-pylance # Pylance Extension
            installVSCodeExtension ms-toolsai.jupyter # Jupyter Notebook support
            installVSCodeExtension ikuyadeu.r # R programming language
            installVSCodeExtension mikhail-arkhipov.r # R tools
        fi

        # Shell Scripting Extensions
        if [[ $installShell -eq 1 ]]
        then
            installVSCodeExtension lizebang.bash-extension-pack # Bash Extension Pack
            installVSCodeExtension foxundermoon.shell-format # Shell format
            installVSCodeExtension Remisa.shellman # Shell snippets
            installVSCodeExtension timonwong.shellcheck # Shellcheck for VS Code
            installVSCodeExtension mads-hartmann.bash-ide-vscode # IDE for Bash
            installVSCodeExtension rogalmic.bash-debug # Bash Debugger
            installVSCodeExtension rpinski.shebang-snippets # Shebang Snippets
            installVSCodeExtension ms-vscode.powershell # Powershell
        fi

        # Database Extensions
        if [[ $installDatabase -eq 1 ]]
        then
            installVSCodeExtension alexcvzz.vscode-sqlite # SQLite Databases
            installVSCodeExtension adpyke.vscode-sql-formatter # SQL Formatter
            installVSCodeExtension bajdzis.vscode-database # mysql, postgres database support
            installVSCodeExtension mtxr.sqltools # Database management tools
        fi

        if ((installed > 0)); then
            echo "$installed extensions installed"
        else
            echo "No extensions to install"
        fi
    }
}

processPackageList() {
    installAndroid=0
    installDataScience=0
    installDatabase=0
    installDevOps=0
    installPrototyping=0
    installJava=0
    installReact=0
    installShell=0
    IFS=$'\n' read -d '' -r -a packageList < "$dialogtmpfile"
    for pack in "${packageList[@]}"
    do
        case $pack in
            1) installRuby=1 ;;
            2) installReact=1 ;;
            3) installJava=1 ;;
            4) installAndroid=1 ;;
            5) installDataScience=1 ;;
            6) installDevOps=1 ;;
            7) installDatabase=1 ;;
            8) installShell ;;
            9) installPrototyping=1 ;;
            HELP*) true ;; # ignore any HELP lines
        esac
    done
}

promptForInfo() {
    while
        dialog --clear --backtitle "$title" --title "User Information" --hline "Use TAB to navigate to buttons" \
            --form "Enter information for Git" 9 60 0 \
            "Full Name:" 1 1 "$name"   1 12 30 255 \
            "Email:"     2 1 "$email"  2 12 40 255 \
            "User ID:"   3 1 "$userId" 3 12 10 255 2> $dialogtmpfile

        result=$?
        case $result in
            0)
                IFS=$'\n' read -r -d '' name email userId < $dialogtmpfile
                ;;
            *)
                echo "Installer canceled!"
                exit 1
                ;;
        esac
        [[ "$name" == "" || "$email" == "" || "$userId" == "" ]]
    do
        dialog --clear --backtitle "$title" --title "Error[!]" --msgbox \
            "\nAll fields are required. Please enter name, email, and user ID." 8 40
    done

    defaultItem=1
    while
        if [[ $installRuby -eq 1 ]] ; then flagRuby="on" ; else flagRuby="off" ; fi
        if [[ $installReact -eq 1 ]] ; then flagReact="on" ; else flagReact="off" ; fi
        if [[ $installJava -eq 1 ]] ; then flagJava="on" ; else flagJava="off" ; fi
        if [[ $installAndroid -eq 1 ]] ; then flagAndroid="on" ; else flagAndroid="off" ; fi
        if [[ $installDataScience -eq 1 ]] ; then flagDataScience="on" ; else flagDataScience="off" ; fi
        if [[ $installDevOps -eq 1 ]] ; then flagDevOps="on" ; else flagDevOps="off" ; fi
        if [[ $installDatabase -eq 1 ]] ; then flagDatabase="on" ; else flagDatabase="off" ; fi
        if [[ $installShell -eq 1 ]] ; then flagShell="on" ; else flagShell="off" ; fi
        if [[ $installPrototyping -eq 1 ]] ; then flagPrototyping="on" ; else flagPrototyping="off" ; fi
        dialog --clear --backtitle "$title" --title "Package Chooser" --default-item "$defaultItem" \
            --help-button --help-label "Details" --help-status --separate-output \
            --checklist \
            "Choose Development Tools to Install\n\nUse SPACE to select, arrows to navigate, \
            ENTER when done. Press Details to see the \nindividual tools in the set." 20 50 9 \
            1 "Ruby Development" "$flagRuby" \
            2 "React Development" "$flagReact" \
            3 "Java Development" "$flagJava" \
            4 "Android Development" "$flagAndroid" \
            5 "Data Science" "$flagDataScience" \
            6 "DevOps" "$flagDevOps" \
            7 "Database Management" "$flagDatabase" \
            8 "Shell Scripting" "$flagShell" \
            9 "Prototype Design" "$flagPrototyping" 2> $dialogtmpfile

        result=$?
        case $result in
            0)
                processPackageList
                ;;
            2)
                read -r helpPrompt < "$dialogtmpfile"
                processPackageList
                case $helpPrompt in
                    "HELP 1") pack="Ruby Development"; IFS=$'\n' apps="${rubyInstall[*]}"; defaultItem=1 ;;
                    "HELP 2") pack="React Development"; IFS=$'\n' apps="${reactInstall[*]}"; defaultItem=2 ;;
                    "HELP 3") pack="Java Development"; IFS=$'\n' apps="${javaInstall[*]}"; defaultItem=3 ;;
                    "HELP 4") pack="Android Development"; IFS=$'\n' apps="${androidInstall[*]}"; defaultItem=4 ;;
                    "HELP 5") pack="Data Science"; IFS=$'\n' apps="${dataScienceInstall[*]}"; defaultItem=5 ;;
                    "HELP 6") pack="DevOps"; IFS=$'\n' apps="${devOpsInstall[*]}"; defaultItem=6 ;;
                    "HELP 7") pack="Database Management"; IFS=$'\n' apps="${databaseInstall[*]}"; defaultItem=7 ;;
                    "HELP 8") pack="Shell Scripting"; IFS=$'\n' apps="${shellInstall[*]}"; defaultItem=8 ;;
                    "HELP 9") pack="Prototype Design"; IFS=$'\n' apps="${prototypingInstall[*]}"; defaultItem=9 ;;
                esac
                dialog --clear --backtitle "$title" --title "Package Info" --cr-wrap --msgbox \
                    "The following applications will be installed for $pack:\n\n$apps" 15 50
                ;;
            *)
                echo "Installer canceled!"
                exit 1
                ;;
        esac
        [[ $result -ne 0 ]]
    do : ; done

    dialog --clear --backtitle "$title" --title "IDE Chooser" --checklist \
        "Choose Editor(s)/IDE(s) to Install" 15 60 9 \
        1 "Atom" off \
        2 "IntelliJ Idea" off \
        3 "Eclipse Java" off \
        4 "MacVim" off \
        5 "PyCharm CE" off \
        6 "Visual Studio Code" on 2> $dialogtmpfile

    result=$?
    case $result in
        0)
            IFS=" " read -r -a packageList < "$dialogtmpfile"
            for pack in "${packageList[@]}"
            do
                case $pack in
                    1) editorInstall+=( "homebrew/cask/atom" ) ;;
                    2) editorInstall+=( "homebrew/cask/intellij-idea-ce" ) ;;
                    3) editorInstall+=( "homebrew/cask/eclipse-java" ) ;;
                    4) editorInstall+=( "homebrew/cask/macvim" ) ;;
                    5) editorInstall+=( "homebrew/cask/pycharm-ce" ) ;;
                    6) editorInstall+=( "homebrew/cask/visual-studio-code" ) ;;
                esac
            done
            ;;
        *)
            echo "Installer canceled!"
            exit 1
            ;;
    esac

    dialog --clear --backtitle "$title" --title "Browser Chooser" --checklist \
        "Choose Browser(s) to Install" 7 50 0 \
        1 "Firefox" on \
        2 "Google Chrome" on 2> $dialogtmpfile

    result=$?
    case $result in
        0)
            IFS=" " read -r -a packageList < "$dialogtmpfile"
            for pack in "${packageList[@]}"
            do
                case $pack in
                    1) browserInstall+=( "homebrew/cask/firefox" ) ;;
                    2) browserInstall+=( "homebrew/cask/google-chrome" ) ;;
                esac
            done
            ;;
        *)
            echo "Installer canceled!"
            exit 1
            ;;
    esac

    dialog --clear --backtitle "$title" --title "Git Manager Chooser" --checklist \
        "Choose application(s) to manage Git" 7 50 0 \
        1 "Fork" off \
        2 "GitKraken" off 2> $dialogtmpfile

    result=$?
    case $result in
        0)
            IFS=" " read -r -a packageList < "$dialogtmpfile"
            for pack in "${packageList[@]}"
            do
                case $pack in
                    1) gitUiInstall+=( "homebrew/cask/fork" ) ;;
                    2) gitUiInstall+=( "homebrew/cask/gitkraken" ) ;;
                esac
            done
            ;;
        *)
            echo "Installer canceled!"
            exit 1
            ;;
    esac

    dialog --clear --backtitle "$title" --title "Application Chooser" --item-help --checklist \
        "Choose optional applications to install" 7 50 0 \
        1 "CPU Info" off "CPU Usage graph in the Menu Bar" \
        2 "HTop" off "Interactive process viewer" \
        3 "MacDown" off "Markdown editor for MacOS" 2> $dialogtmpfile

    result=$?
    case $result in
        0)
            IFS=" " read -r -a packageList < "$dialogtmpfile"
            for pack in "${packageList[@]}"
            do
                case $pack in
                    1) optionalInstall+=( "homebrew/cask/cpuinfo" ) ;;
                    2) optionalInstall+=( "htop" ) ;;
                    3) optionalInstall+=( "homebrew/cask/macdown" ) ;;
                esac
            done
            ;;
        *)
            echo "Installer canceled!"
            exit 1
            ;;
    esac
}

configureGit() {
    echo "Configuring Git..."
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global github.user "$userId"
    git config --global color.ui auto
    git config --global core.autocrlf input
    git config --global credential.helper osxkeychain
    git config --global push.default simple
}

configureMac() {
    echo "Configuring Mac..."

    # Disable automatic capitalization as it’s annoying when typing code
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

    # Disable smart dashes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Disable automatic period substitution as it’s annoying when typing code
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

    # Disable smart quotes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    # Disable auto-correct as it’s annoying when typing code
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Add applications to Mac Dock
    for item in "${dockItems[@]}"
    do
        if [ -e "/Applications/$item.app" ]
        then
            (dockutil --find "$item" "$HOME" || dockutil --add "/Applications/$item.app") &> /dev/null
        fi
    done
}

configureIterm2() {
    echo "Configuring iTerm2..."

    # Load iTerm2 shell integration
    /bin/bash -c "$(curl -fsSL https://iterm2.com/shell_integration/install_shell_integration.sh)"
}

# Now that everything's defined, run the installer

export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_UPDATE_PREINSTALL=0
export HOMEBREW_INSTALL_BADGE=" 🧃 "

promptToStart
makeTempFiles
parseGitConfig
initXCode
initHomebrew
tapHomebrew
installBasePackages
promptForInfo
clear
installPackages
installFonts
installAllVSCodeExtensions
startServices
configureGit
configureMac
configureIterm2
cleanupHomebrew

unset HOMEBREW_UPDATE_PREINSTALL
unset HOMEBREW_NO_ENV_HINTS
unset HOMEBREW_NO_INSTALL_CLEANUP

cat <<EOF

To get a list of applications installed by this script, enter
    brew list
from your terminal. This list will include command-line
applications (Formulae) as well as GUI applications and
fonts (Casks).

Installation complete!

EOF

osascript -e "display notification \"Installation complete"'!'"\" with title \"$title\""
