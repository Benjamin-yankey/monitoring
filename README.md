# Complete CI/CD Pipeline with Jenkins

[![Jenkins](https://img.shields.io/badge/Jenkins-LTS-red)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue)](https://www.docker.com/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green)](https://nodejs.org/)
[![AWS](https://img.shields.io/badge/AWS-EC2-orange)](https://aws.amazon.com/)

A production-ready CI/CD pipeline that automates building, testing, containerizing, and deploying a Node.js web application using Jenkins, Docker, and AWS EC2.

## 🎯 Project Overview

This project demonstrates a complete CI/CD pipeline with:
- **Automated Testing**: Unit tests run on every build
- **Containerization**: Docker-based deployment
- **Registry Integration**: Automatic push to Docker Hub
- **Cloud Deployment**: Automated deployment to AWS EC2
- **Infrastructure as Code**: Terraform for AWS provisioning

**Pipeline Duration**: 2-3 minutes per deployment

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- Docker Hub account
- AWS EC2 key pair

### Deploy in 15 Minutes

```bash
# 1. Clone repository
git clone <your-repo-url>
cd Project_Complete_CICD_Pipeline_Jenkins

# 2. Deploy infrastructure (SECURE)
cd terraform
cp terraform.tfvars.example.secure terraform.tfvars
# Edit terraform.tfvars: Set allowed_ips to YOUR_IP/32
./validate-security.sh  # Validate security configuration
./deploy-secure.sh      # Automated secure deployment

# 3. Configure Jenkins
# Access Jenkins at http://<JENKINS_IP>:8080
# Password in AWS Secrets Manager
# Add credentials: registry_creds, ec2_ssh

# 4. Create and run pipeline
# Jenkins → New Item → Pipeline
# Configure with Git repo and Jenkinsfile
# Build Now

# 5. Verify
curl http://<EC2_IP>:5000/health
```

**For detailed instructions, see [QUICKSTART.md](QUICKSTART.md)**

## 📋 Documentation

- **[SECURITY-FIXES-SUMMARY.md](SECURITY-FIXES-SUMMARY.md)** - Security vulnerability fixes implemented
- **[SECURITY-REMEDIATION.md](SECURITY-REMEDIATION.md)** - Detailed security remediation guide
- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 15 minutes
- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Detailed setup instructions
- **[RUNBOOK.md](RUNBOOK.md)** - Operations and troubleshooting guide
- **[EVIDENCE-GUIDE.md](EVIDENCE-GUIDE.md)** - Evidence collection for submission
- **[SUBMISSION-CHECKLIST.md](SUBMISSION-CHECKLIST.md)** - Pre-submission checklist
- **[INDUSTRY-STANDARDS.md](INDUSTRY-STANDARDS.md)** - Industry standards compliance
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[SECURITY.md](SECURITY.md)** - Security policy

## 🏗️ Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────────┐
│   GitHub    │─────▶│   Jenkins    │─────▶│ Docker Hub  │─────▶│   AWS EC2    │
│ Repository  │      │   Server     │      │  Registry   │      │  App Server  │
└─────────────┘      └──────────────┘      └─────────────┘      └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  Unit Tests  │
                     └──────────────┘
```

## 🔄 Pipeline Stages

1. **Checkout** - Clone source code from Git
2. **Install/Build** - Install Node.js dependencies
3. **Test** - Run unit tests with Jest
4. **Docker Build** - Build container image
5. **Push Image** - Push to Docker Hub registry
6. **Deploy** - Deploy to EC2 via SSH

## 📁 Project Structure

```
Project_Complete_CICD_Pipeline_Jenkins/
├── app.js                      # Node.js Express application
├── app.test.js                 # Unit tests
├── package.json                # Dependencies
├── Dockerfile                  # Container definition
├── Jenkinsfile                 # Pipeline definition
├── terraform/                  # Infrastructure as Code
│   ├── main.tf
│   ├── modules/
│   └── ...
├── screenshots/                # Evidence screenshots
├── logs/                       # Collected logs
└── *.md                        # Documentation
```

## 🧪 Testing

```bash
# Install dependencies
npm install

# Run tests
npm test

# Run locally
npm start
curl http://localhost:5000/health
```

## 📸 Evidence Collection

```bash
# Automated collection
./collect-evidence.sh

# Manual screenshots needed:
# - Jenkins pipeline success
# - Application in browser
# - Docker Hub repository
# - EC2 container status
```

See [EVIDENCE-GUIDE.md](EVIDENCE-GUIDE.md) for complete instructions.

## 🔧 Configuration

### Jenkins Credentials Required

| ID | Type | Description |
|---|---|---|
| `registry_creds` | Username/Password | Docker Hub credentials |
| `ec2_ssh` | SSH Private Key | EC2 access key |

### Environment Variables

| Variable | Description | Example |
|---|---|---|
| `DOCKER_IMAGE` | Image name | `cicd-node-app` |
| `CONTAINER_NAME` | Container name | `node-app` |
| `EC2_HOST` | EC2 public IP | `3.15.123.45` |

## 🚨 Troubleshooting

### Pipeline Fails
```bash
# Check Jenkins console output
# Verify credentials are correct
# Test SSH connection manually
```

### Application Not Accessible
```bash
# Check security group allows port 5000
# Verify container is running
ssh -i key.pem ec2-user@<EC2_IP> "docker ps"
```

**For more troubleshooting, see [RUNBOOK.md](RUNBOOK.md)**

## 🧹 Cleanup

```bash
cd terraform
terraform destroy
```

## ✅ Submission Requirements

This project meets all requirements:
- ✅ Simple web application (Node.js/Express)
- ✅ Unit tests with Jest
- ✅ Dockerfile for containerization
- ✅ Complete Jenkinsfile with all stages
- ✅ Jenkins credentials configured
- ✅ Automated deployment to EC2
- ✅ Resource cleanup implemented
- ✅ Comprehensive documentation
- ✅ Evidence collection tools

## 📊 Project Highlights

- **Infrastructure as Code**: Complete Terraform modules for AWS
- **Security Hardened**: Restricted access, IAM roles, Secrets Manager integration
- **Automated Security Validation**: Pre-deployment security checks
- **Secrets Management**: AWS Secrets Manager for sensitive data
- **Network Security**: Restricted egress rules, security group best practices
- **Automation**: Full CI/CD automation from commit to deployment
- **Monitoring**: Health check endpoints and logging
- **Documentation**: Comprehensive guides and runbooks
- **Evidence**: Automated collection scripts and templates

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

MIT License

## 👥 Author

Your Name - [GitHub Profile](https://github.com/your-username)

## 🙏 Acknowledgments

- Jenkins community
- Docker
- AWS
- Node.js and Express

---

**⭐ Star this repo if you find it helpful!**

**📧 Questions?** Open an issue or check the documentation.