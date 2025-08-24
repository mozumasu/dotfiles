
# ----------------------------------------------------
# Options
# ----------------------------------------------------

# ----------------------------------------------------
# History
# ----------------------------------------------------
# Record additional information (execution time, exit status)
setopt EXTENDED_HISTORY
setopt share_history
# Make history editable between recall and execution.
setopt hist_verify


# Setting the command to add
# Excludes only if it is the same as the previous command.
setopt hist_ignore_dups
# Except when the same command exists throughout the history.
setopt hist_ignore_all_dups
# Command lines starting with a space are removed from the history list.
setopt hist_ignore_space
# The history command is not registered in the history.
setopt hist_no_store
# Fill in any extra spaces.
setopt hist_reduce_blanks
# Nothing is the same as the old command.
setopt hist_save_no_dups
# Automatically expand history when saving
setopt hist_expand
# Keep history instantly
setopt inc_append_history

# ----------------------------------------------------
# cd
# ----------------------------------------------------
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups

# ----------------------------------------------------
# other
# ----------------------------------------------------
# Background job priority (ionice) behaves the same as bash
unsetopt bg_nice
# List of completion candidates
setopt list_packed
setopt no_beep
# Do not display file type launch at the end of completion candidates.
unsetopt list_types


# ----------------------------------------------------
# tty
# ----------------------------------------------------
# only run if stdin is a tty
if [[ -t 0 ]]; then
  stty -ixon
fi
