#!/bin/sh
# Maven Wrapper that uses Adoptium JDK (with javac) instead of IntelliJ's JRE
export JAVA_HOME="/home/german/.local/share/jdks/jdk-21.0.7+6"
MAVEN_HOME="/home/german/.local/share/JetBrains/Toolbox/apps/intellij-idea/plugins/maven/lib/maven3"

if [ -x "$MAVEN_HOME/bin/mvn" ]; then
    exec "$MAVEN_HOME/bin/mvn" "$@"
else
    echo "ERROR: Maven not found. Installed Maven wrapper." >&2
    exit 1
fi
