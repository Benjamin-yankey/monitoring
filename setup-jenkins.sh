#!/bin/bash
# Install Jenkins on EC2 with Docker agent support (run after Docker setup)

# Install Java (required for Jenkins controller)
sudo yum install -y java-11-openjdk

# Add Jenkins repo and install
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Add jenkins user to docker group for Docker agent support
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins

# Build Jenkins agent Docker image
docker build -f Dockerfile.jenkins-agent -t jenkins-agent:latest .

# Configure Jenkins to use Docker agents:
# 1. Go to Jenkins > Manage Jenkins > Manage Nodes and Clouds > Configure System
# 2. Under "Cloud", add a "Docker" cloud
# 3. Docker Host URI: unix:///var/run/docker.sock (or tcp://127.0.0.1:2375)
# 4. Add Docker Agent templates using "jenkins-agent:latest" image
# 5. Set up appropriate labels and resource allocation

echo "Jenkins installed! Access it at http://YOUR_EC2_IP:8080"
echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "Build the Jenkins agent image with: docker build -f Dockerfile.jenkins-agent -t jenkins-agent:latest ."