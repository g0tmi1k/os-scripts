#--- Screen
alias screen="screen -xRR"


#--- Colouring command output
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


#--- Directory listing
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'


#--- Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."


#--- Package management
alias upd="sudo apt-get update"
alias upg="sudo apt-get upgrade"
alias ins="sudo apt-get install"
alias rem="sudo apt-get purge"
alias fix="sudo apt-get install -f"


#--- Extract file. (E.g "ex package.tar.bz2")
ex() {
    if [[ -f $1 ]]; then
        case $1 in
            *.tar.bz2)   tar xjf $1  ;;
            *.tar.gz)    tar xzf $1  ;;
            *.bz2)       bunzip2 $1  ;;
            *.rar)       rar x $1    ;;
            *.gz)        gunzip $1   ;;
            *.tar)       tar xf $1   ;;
            *.tbz2)      tar xjf $1  ;;
            *.tgz)       tar xzf $1  ;;
            *.zip)       unzip $1    ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1     ;;
            *)           echo $1 cannot be extracted ;;
        esac
    else
        echo $1 is not a valid file
    fi
}
