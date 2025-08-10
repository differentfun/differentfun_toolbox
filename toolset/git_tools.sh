#!/bin/bash

# git_tools – by DifferentFun
# Manage Git identity, repositories, commits and pushes

# Show current Git identity
show_identity() {
    echo "========== CURRENT GIT IDENTITY =========="
    echo "Name  : $(git config --global user.name)"
    echo "Email : $(git config --global user.email)"
    echo "Token : ${GITHUB_TOKEN:+(GITHUB_TOKEN is set)}"
    echo "=========================================="
    zenity --info --title="git_tools – by DifferentFun" --text="Current identity printed to terminal." --width=300
}

# Change Git identity
change_identity() {
    NAME=$(zenity --entry --title="git_tools – by DifferentFun" --text="Enter Git user.name:")
    [ -z "$NAME" ] && zenity --error --text="Name is required!" && return

    EMAIL=$(zenity --entry --title="git_tools – by DifferentFun" --text="Enter Git user.email:")
    [ -z "$EMAIL" ] && zenity --error --text="Email is required!" && return

    TOKEN=$(zenity --entry --title="git_tools – by DifferentFun" --text="Enter GitHub token (optional):")

    git config --global user.name "$NAME"
    git config --global user.email "$EMAIL"

    export GITHUB_TOKEN="$TOKEN"

    echo "✅ Git identity updated:"
    echo "Name  : $NAME"
    echo "Email : $EMAIL"
    if [ -n "$TOKEN" ]; then
        echo "Token : (GITHUB_TOKEN exported in this session)"
    else
        echo "Token : (not set)"
    fi

    zenity --info --title="git_tools – by DifferentFun" --text="Git identity updated!" --width=250
}

# Initialize Git repository
init_repo() {
    DIR=$(zenity --file-selection --directory --title="Select folder to initialize Git repository")
    [ -z "$DIR" ] && return

    if [ -d "$DIR/.git" ]; then
        zenity --warning --title="git_tools – by DifferentFun" --text="This folder is already a Git repository." --width=300
        return
    fi

    cd "$DIR" && git init
    git branch -M main

    # Create initial empty commit to activate branch
    touch .gitkeep
    git add .gitkeep
    git commit -m "Initial commit"

    echo "✅ Initialized Git repo in: $DIR (branch: main with initial commit)"

    REMOTE_URL=$(zenity --entry --title="Set Remote Origin" --text="Enter remote repository URL (optional):")

    if [ -n "$REMOTE_URL" ]; then
        git remote add origin "$REMOTE_URL"
        echo "🔗 Remote 'origin' set to: $REMOTE_URL"
        zenity --info --title="git_tools – by DifferentFun" --text="Repository initialized with remote:\n$REMOTE_URL" --width=350
    else
        zenity --info --title="git_tools – by DifferentFun" --text="Repository initialized without remote." --width=300
    fi
}

# Make a commit
make_commit() {
    DIR=$(zenity --file-selection --directory --title="Select Git repository to commit in")
    [ -z "$DIR" ] && return

    if [ ! -d "$DIR/.git" ]; then
        zenity --error --title="git_tools – by DifferentFun" --text="Not a Git repository." --width=300
        return
    fi

    cd "$DIR"

    BRANCHES=($(git branch --format="%(refname:short)"))
    if [ ${#BRANCHES[@]} -eq 0 ]; then
        zenity --error --title="git_tools – by DifferentFun" --text="No branches found." --width=300
        return
    fi

    SELECTED_BRANCH=$(zenity --list --title="Choose branch for commit" --column="Branches" "${BRANCHES[@]}" --height=300 --width=300)
    [ -z "$SELECTED_BRANCH" ] && return

    git checkout "$SELECTED_BRANCH"
    git add .

    # Check if there are staged changes
    if git diff --cached --quiet; then
        zenity --info --title="git_tools – by DifferentFun" --text="No changes staged. Nothing to commit." --width=300
        return
    fi

    MSG=$(zenity --entry --title="git_tools – by DifferentFun" --text="Enter commit message:")
    [ -z "$MSG" ] && zenity --error --text="Commit message is required!" --width=300 && return

    git commit -m "$MSG"

    echo "✅ Commit created on branch '$SELECTED_BRANCH' in: $DIR"
    zenity --info --title="git_tools – by DifferentFun" --text="Commit completed on branch:\n$SELECTED_BRANCH" --width=300
}

# Push to remote
push_repo() {
    DIR=$(zenity --file-selection --directory --title="Select Git repository to push")
    [ -z "$DIR" ] && return

    if [ ! -d "$DIR/.git" ]; then
        zenity --error --title="git_tools – by DifferentFun" --text="Not a Git repository." --width=300
        return
    fi

    cd "$DIR"

    git remote -v | grep origin &> /dev/null
    if [ $? -ne 0 ]; then
        zenity --error --title="git_tools – by DifferentFun" --text="No remote named 'origin' set." --width=300
        return
    fi

    git push origin HEAD

    echo "📤 Pushed current branch to origin."
    zenity --info --title="git_tools – by DifferentFun" --text="Push completed to remote 'origin'." --width=300
}

# Force push to remote
force_push_repo() {
    DIR=$(zenity --file-selection --directory --title="Select Git repository to FORCE push")
    [ -z "$DIR" ] && return

    if [ ! -d "$DIR/.git" ]; then
        zenity --error --title="git_tools – by DifferentFun" --text="Not a Git repository." --width=300
        return
    fi

    cd "$DIR"

    git remote -v | grep origin &> /dev/null
    if [ $? -ne 0 ]; then
        zenity --error --title="git_tools – by DifferentFun" --text="No remote named 'origin' set." --width=300
        return
    fi

    zenity --question --title="git_tools – by DifferentFun" \
        --text="⚠️ This will FORCE push to 'origin', overwriting remote history.\nAre you sure?" --width=400

    if [ $? -eq 0 ]; then
        git push --force origin HEAD
        echo "🔥 Force pushed current branch to origin."
        zenity --info --title="git_tools – by DifferentFun" --text="Force push completed to remote 'origin'." --width=300
    else
        zenity --info --title="git_tools – by DifferentFun" --text="Operation cancelled." --width=300
    fi
}


# Clean Git information from folder
clean_git_info() {
    DIR=$(zenity --file-selection --directory --title="Select folder to remove Git data from")
    [ -z "$DIR" ] && return

    if [ ! -d "$DIR/.git" ]; then
        zenity --info --title="git_tools – by DifferentFun" --text="No .git directory found in selected folder." --width=300
        return
    fi

    zenity --question --title="git_tools – by DifferentFun" \
        --text="Are you sure you want to permanently remove .git information from:\n$DIR?" --width=350

    if [ $? -eq 0 ]; then
        rm -rf "$DIR/.git"
        echo "🧹 .git directory removed from: $DIR"
        zenity --info --title="git_tools – by DifferentFun" --text=".git directory removed from:\n$DIR" --width=300
    else
        zenity --info --title="git_tools – by DifferentFun" --text="Operation cancelled." --width=300
    fi
}

enable_credential_save() {
    git config --global credential.helper store
    zenity --info --title="git_tools – by DifferentFun" \
        --text="Git is now configured to save credentials permanently." --width=350
}

fix_remote_url() {
    DIR=$(zenity --file-selection --directory --title="Select Git repository to fix remote URL")
    [ -z "$DIR" ] && return

    cd "$DIR"

    zenity --question --title="Fix Remote URL" \
        --text="This will reset the remote 'origin' to use your GitHub username.\nContinue?"

    if [ $? -eq 0 ]; then
        USER=$(zenity --entry --title="GitHub Username" --text="Enter your GitHub username (e.g., differentfun):")
        REPO=$(zenity --entry --title="Repository Name" --text="Enter your repository name (e.g., differentfun_toolbox):")
        [ -z "$USER" ] || [ -z "$REPO" ] && zenity --error --text="Both fields are required!" && return

        NEW_URL="https://$USER@github.com/$USER/$REPO.git"
        git remote set-url origin "$NEW_URL"
        echo "🔧 Remote 'origin' set to: $NEW_URL"
        zenity --info --title="git_tools – by DifferentFun" --text="Remote URL updated to:\n$NEW_URL" --width=400
    fi
}


# Main menu loop
while true; do
	CHOICE=$(zenity --list \
		--title="git_tools – by DifferentFun" \
		--width=600 --height=400 \
		--column="Action" \
		"Show Current Identity" \
		"Change Current Identity" \
		"Initialize Git Repository" \
		"Make a Commit" \
		"Push to Remote" \
		"Force Push to Remote" \
		"Clean Git Information from Folder" \
		"Enable Permanent Credential Save" \
		"Fix Remote URL with Token" \
		"Exit")




    case "$CHOICE" in
        "Show Current Identity") show_identity ;;
        "Change Current Identity") change_identity ;;
        "Initialize Git Repository") init_repo ;;
        "Make a Commit") make_commit ;;
        "Push to Remote") push_repo ;;
        "Clean Git Information from Folder") clean_git_info ;;
        "Force Push to Remote") force_push_repo ;;
        "Enable Permanent Credential Save") enable_credential_save ;;
        "Fix Remote URL with Token") fix_remote_url ;;
        "Exit") break ;;
        *) break ;;
    esac
done
