#!/bin/bash

set -e

echo "Updating package list..."
sudo dnf update -y

echo "Installing Java JDK 17..."
sudo dnf install -y java-17-openjdk java-17-openjdk-devel

echo "Setting Java 17 as the default Java version..."
sudo alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-openjdk/bin/java 1
sudo alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-17-openjdk/bin/javac 1
sudo alternatives --set java /usr/lib/jvm/java-17-openjdk/bin/java
sudo alternatives --set javac /usr/lib/jvm/java-17-openjdk/bin/javac

echo "Checking Java version..."
java -version

echo "Java JDK 17 installation and setup completed successfully!"
