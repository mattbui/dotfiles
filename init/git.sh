#!/bin/sh

git config --global user.email matthew@cinnamon.is
git config --global user.username mattbui
# git config --global branch.autosetuprebase always

git config --global core.excludesfile $HOME/.gitignore_global

# git config --global user.signingkey <key_id>
git config --global commit.gpgsign true

