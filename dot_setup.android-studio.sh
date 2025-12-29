# Install Android Studio (https://developer.android.com/studio), if needed
# brew list android-studio &> /dev/null || brew install --cask android-studio

# Ensure Android SDK is installed
[ -d $HOME/Library/Android/sdk ] && export ANDROID_HOME=$HOME/Library/Android/sdk
[ -d $ANDROID_HOME/emulator ] && export PATH=$PATH:$ANDROID_HOME/emulator
[ -d $ANDROID_HOME/platform-tools ] && export PATH=$PATH:$ANDROID_HOME/platform-tools
