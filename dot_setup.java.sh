# Install Java (https://www.oracle.com/java/technologies/javase-jdk17-downloads.html), if needed
# brew list openjdk@17 &> /dev/null || brew install openjdk@17

[ -d /opt/homebrew/opt/openjdk@17 ] || {
  echo "Java JDK not found - please install OpenJDK 17"
  return 1 || exit 1
}

[ -d /opt/homebrew/opt/openjdk@17 ] && {
  export JAVA_HOME=/opt/homebrew/opt/openjdk@17
  export PATH="$JAVA_HOME/bin:$PATH"
}
