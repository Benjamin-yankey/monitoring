# Jenkins Docker Agent Setup Guide

This guide explains how to configure Jenkins to use Docker agents instead of relying on the pre-installed Java runtime.

## Overview

By using Docker agents, Jenkins:
- Isolates build environments
- Eliminates dependency on pre-installed tools (Java, Node.js, Docker, etc.)
- Scales horizontally with Docker containers
- Provides consistent build environments

## Prerequisites

- Jenkins controller running (JVM-based)
- Docker installed on the Jenkins host
- Jenkins user added to docker group: `sudo usermod -a -G docker jenkins`

## Setup Methods

### Method 1: Docker Compose (Recommended for Quick Start)

```bash
# Build the Jenkins agent image
docker build -f Dockerfile.jenkins-agent -t jenkins-agent:latest .

# Start Jenkins with Docker agents using docker-compose
docker-compose -f docker-compose.jenkins.yml up -d
```

Access Jenkins at `http://localhost:8080`

### Method 2: Manual Docker Agent Configuration

#### Step 1: Build the Agent Image

```bash
docker build -f Dockerfile.jenkins-agent -t jenkins-agent:latest .
```

#### Step 2: Configure Docker Cloud in Jenkins UI

1. Navigate to **Manage Jenkins** → **Manage Nodes and Clouds** → **Configure System**
2. Under **Cloud**, click **New cloud** and select **Docker**
3. Set **Docker Host URI** to: `unix:///var/run/docker.sock`
4. Click **Test Connection** to verify

#### Step 3: Add Docker Agent Template

1. In the Docker cloud settings, click **Docker Agent templates**
2. Click **Add Docker Template**
3. Configure:
   - **Docker Image**: `jenkins-agent:latest`
   - **Labels**: `docker` (or any label you prefer)
   - **Remote working directory**: `/home/jenkins/agent`
   - **Pull strategy**: `Pull once and update latest`

#### Step 4: Update Jenkinsfile

The Jenkinsfile now uses the Docker agent:

```groovy
pipeline {
    agent {
        docker {
            image 'jenkins-agent:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    // ... rest of pipeline
}
```

## Jenkins Agent Docker Image Contents

The `Dockerfile.jenkins-agent` includes:
- Node.js and npm (for application builds)
- Docker CLI (for building and pushing images)
- Git (for version control)
- curl and wget (for downloading resources)

## Troubleshooting

### Agent fails to connect
- Verify Docker socket is accessible: `ls -l /var/run/docker.sock`
- Ensure Jenkins user is in docker group: `id jenkins`
- Check Jenkins logs: `docker logs jenkins`

### Docker command not found in agent
- Verify Docker socket is mounted: `-v /var/run/docker.sock:/var/run/docker.sock`
- Ensure docker.io package is installed in agent image

### Permission denied errors
- Add Jenkins user to docker group: `sudo usermod -a -G docker jenkins`
- Restart Jenkins: `sudo systemctl restart jenkins` or `docker restart jenkins`

## Running Builds

Once configured:
1. Create a pipeline using the `Jenkinsfile`
2. When the pipeline runs, Jenkins automatically creates a Docker container
3. The build executes inside the container with all required tools
4. The container is cleaned up after the build completes

## Cleanup

To remove Docker agents and images:

```bash
# Stop and remove containers
docker-compose -f docker-compose.jenkins.yml down

# Remove Jenkins agent image
docker rmi jenkins-agent:latest

# Remove Jenkins home volume (if needed)
docker volume rm monitoring_jenkins_home
```

## Security Considerations

- **Docker socket access**: Mounting `/var/run/docker.sock` gives containers Docker privileges. Use with caution in multi-tenant environments.
- **Image scanning**: Regularly scan Docker images for vulnerabilities.
- **Registry credentials**: Store securely in Jenkins credentials manager.

## References

- [Jenkins Docker Plugin](https://plugins.jenkins.io/docker-plugin/)
- [Jenkins Agent Docker Image](https://hub.docker.com/r/jenkins/agent)
- [Dockerfile.jenkins-agent](./Dockerfile.jenkins-agent)
- [docker-compose.jenkins.yml](./docker-compose.jenkins.yml)
