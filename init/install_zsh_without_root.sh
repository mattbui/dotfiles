# # Install Zsh without root privileges
# ## Instructions
# 1) bash install_zsh.sh
# 2) edit .zshrc (add the path to your Zsh binary to the PATH variable, etc.)
# 3) add `set-option -g default-shell <path to zsh>/bin/zsh` to `~/.tmux.conf`
# 4) also see comments for potential further notes
#
# Elaborating on Step 2, this is what I added to my `.zshrc`:
# ```
# # Recently I got a bunch of errors out of the blue (e.g. `colors: function definition file not found`).
# To fix this I had to add this (source: https://github.com/ohmyzsh/ohmyzsh/issues/4607):
# export FPATH=/home/users/mgbckr/services/zsh/share/zsh/5.6.2-test-2/functions:$FPATH
# ZSH_DISABLE_COMPFIX=true
#
# # If you come from bash you might have to change your $PATH, so that we can find the `zsh` executable.
# export PATH=$HOME/services/zsh/bin:$HOME/bin:/usr/local/bin:$PATH
#
# # to enable sherlock commands like `module`
# source /share/software/user/open/lmod/lmod/init/bash
# ```
#
# References: https://www.drewsilcock.co.uk/compiling-zsh
#
# ## Notes:
#
# ### Man pages
# 
# We are not installing the man pages. This causes Zsh's make to complain and exit with an error. Ignore this! 
# If you want man pages, you should probably follow Drews instructions (https://www.drewsilcock.co.uk/compiling-zsh).
# However, when I tried there were some errors which I did not bother to look at. I got pretty far though using the
# following notes:
#   * make sure to use a current gcc: `ml gcc/8.1.0`
#   * use an "old" icmake; I used the one mentioned by Drew: 7.21.00 (https://gitlab.com/fbb-git/icmake/tags)
#   * use an "old" yodl; I used 3.04.00 (https://gitlab.com/fbb-git/yodl/tags)
#   * for icmake run the following (in addition to changing the log files):
#     * ./icm_prepare /
#     * ./icm_bootstrap x
#     * ./icm_install strip all
# This actually got my to compile icmake correctly. For yodl latex was still missing.
#
# ### Ncruses
#
# Ncurses is not only required for compilation. If you delete it after the installation
# the the prompt will constantly break, e.g., when using any of the arrow keys :)
# Thus, it is integrated into the Zsh installation. 
#
# ### Weird prompt and Oh-My-Zsh
# 
# When you run Zsh after installing by this script. The shell is not able to parse the default prompt
# showing a bunch of color encodings and whatnot. I have no idea why this happens. 
# Any other prompt than the default one seems to work fine. 
# Using Oh-My-Zsh also fixes this issue.
# 

ZSH_INSTALL_DIR=$HOME/opt/zsh

# switch to tmp folder
mkdir tmp; cd tmp

# get ncurses
wget https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.3.tar.gz
tar -xf ncurses-6.3.tar.gz
cd ncurses-6.3

# Set cflags and c++ flags to compile with Position Independent Code enabled which we need for compiling zsh
export CXXFLAGS=' -fPIC'
export CFLAGS=' -fPIC'

./configure --prefix=$ZSH_INSTALL_DIR --enable-shared
make

# don't need this probably
#cd progs
#./capconvert
#cd ..

# probably don't need this
#export TERMINFO=/usr/share/terminfo

# test ncurses (only works with the above)
#./test/ncurses

make install
cd ..

# Tell environment where ncurses is
INSTALL_PATH="$ZSH_INSTALL_DIR"
export PATH=$INSTALL_PATH/bin:$PATH
export LD_LIBRARY_PATH=$INSTALL_PATH/lib:$LD_LIBRARY_PATH
export CFLAGS=-I$INSTALL_PATH/include
export CPPFLAGS="-I$INSTALL_PATH/include" LDFLAGS="-L$INSTALL_PATH/lib"


# Zsh

# Get zsh
wget -O zsh.tar.xz https://sourceforge.net/projects/zsh/files/latest/download
mkdir zsh && unxz zsh.tar.xz && tar -xvf zsh.tar -C zsh --strip-components 1
cd zsh

# Produce Makefile and config.h via config.status
./configure --prefix=$ZSH_INSTALL_DIR --enable-shared

make
make install
