#!/bin/bash

# Language packages

APT_PACKAGES_LANGUAGE=(
  # Python
  "python-dev" # Deprecated
  "python3-dev"
  "python3-pip"
  "python3-venv"
  # Java
  "openjdk-8-jdk"
  "openjdk-8-jre"
  "openjdk-11-jdk"
  "openjdk-11-jre"
  "openjdk-13-jdk"
  "openjdk-13-jre"
  "default-jre"
  "default-jdk"
  "oracle-java11-installer-local"
  "oracle-java11-set-default-local"
)

PIP3_PACKAGES_LANGUAGES=(
  "notebook"
  "Send2Trash"
  "pipenv"
)

echolog
echolog "${UL_NC}Installing Language Packages${NC}"
echolog

apt_bulk_install "${APT_PACKAGES_LANGUAGE[@]}"

# Python2 pip (OPTIONAL)
# Ref: https://linuxize.com/post/how-to-install-pip-on-ubuntu-20.04/
curl_install "https://bootstrap.pypa.io/get-pip.py" "${DOWNLOADS_DIR}/get-pip.py"
execlog "sudo python ${DOWNLOADS_DIR}/get-pip.py"

pip_bulk_install 3 "${PIP3_PACKAGES_LANGUAGES[@]}"

export JDK_HOME=/usr/lib/jvm/java-11-openjdk-amd64
## Set java and javac 11 as default
sudo update-alternatives --set java ${JDK_HOME}/bin/java
sudo update-alternatives --set javac ${JDK_HOME}/bin/javac

# Copy the Java path excluding the 'bin/java' to environment if not exist
if grep -q 'JAVA_HOME=' /etc/environment; then
  sudo sed -i "s,^JAVA_HOME=.*,JAVA_HOME=${JDK_HOME}/jre/," /etc/environment ||
    echo "JAVA_HOME=${JDK_HOME}/jre/" | sudo tee -a /etc/environment

  source /etc/environment
fi

## Oracle JDK 11.0.7
# cd $SCRIPTDIR/install/
# sudo cp jdk-11.0.7_linux-x64_bin.tar.gz /var/cache/oracle-jdk11-installer-local && \
#   echo "deb http://ppa.launchpad.net/linuxuprising/java/ubuntu focal main" | \
#   sudo tee /etc/apt/sources.list.d/linuxuprising-java.list && \
#   sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 73C3DB2A && \
#   sudo apt update && \
#   sudo apt install oracle-java11-installer-local -y && \
#   sudo apt install oracle-java11-set-default-local -y && \
#   sudo update-alternatives --set java /usr/lib/jvm/java-11-oracle/bin/java

# # copy the Java path excluding the 'bin/java' if not exist
# grep -q 'JAVA_HOME=' /etc/environment && \
#   sudo sed -i 's,^JAVA_HOME=.*,JAVA_HOME="/usr/lib/jvm/java-11-oracle/",' /etc/environment || \
#   echo 'JAVA_HOME="/usr/lib/jvm/java-11-oracle/"' | sudo tee -a /etc/environment
# source /etc/environment

