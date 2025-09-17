# GitHub Actions Setup Guide for Traffic Sign Detector

This guide will walk you through the final steps to get your containerized Traffic Sign Detector application deployed using GitHub Actions.

## 1. Create GitHub Repository

If you haven't already, create a new GitHub repository for your project.
- Go to [GitHub.com](https://github.com) and sign in.
- Click the **"+"** button in the top right corner and select **"New repository"**.
- Give your repository a name (e.g., `traffic-sign-detector`).
- Choose **Public** or **Private** based on your preference.
- **Do NOT** initialize with a README, .gitignore, or license, as you already have these files locally.
- Click **"Create repository"**.

## 2. Initialize Git in Your Local Project and Push to GitHub

Navigate to your project's root directory in your terminal:

```bash
cd /home/ossama/Documents/yolo
```

Initialize a new Git repository:

```bash
git init
```

Set the default branch to `main`:

```bash
git branch -M main
```

Add your remote GitHub repository URL (replace `YOUR_GITHUB_USERNAME` and `YOUR_REPO_NAME`):

```bash
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git
```
(e.g., `git remote add origin https://github.com/ossamaelouadih/traffic-sign-detector.git`)

Add all your project files to the Git staging area:

```bash
git add .
```

Commit your changes:

```bash
git commit -m "Initial commit: Add project files and containerized CI/CD workflow"
```

Push your code to GitHub:

```bash
git push -u origin main
```

## 3. Create Azure Service Principal for GitHub Actions

GitHub Actions needs credentials to deploy to Azure. Create a Service Principal with Contributor role on your resource group:

```bash
az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID>/resourceGroups/rg-traffic-sign-detector-prod --json-auth
```

**Important:** Copy the entire JSON output. It will look something like this:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

## 4. Add GitHub Secrets

Go to your GitHub repository on the web: `https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/settings/secrets/actions`

Click **"New repository secret"** and add the following secrets:

- **`ACR_USERNAME`**: `acrtrafficsignprod`
- **`ACR_PASSWORD`**: `your-acr-password-here`
- **`DB_ADMIN_PASSWORD`**: `TrafficSign2024!Secure` (This is the password for `psql-traffic-sign-prod-new`)
- **`DJANGO_SECRET_KEY`**: `your-super-secret-django-key-here` (Generate a strong, random key for production)
- **`REDIS_PASSWORD`**: `RedisSecure2024!`
- **`AZURE_CREDENTIALS`**: Paste the entire JSON output from the `az ad sp create-for-rbac` command here.

## 5. Trigger the CI/CD Pipeline

Once the secrets are added, any push to the `main` branch will automatically trigger the GitHub Actions workflow.

If you want to trigger it immediately after setting up secrets, you can make a small, innocuous commit and push it:

```bash
git commit --allow-empty -m "Trigger CI/CD after secrets setup"
git push origin main
```

## 6. Access Your Deployed Application

After the GitHub Actions workflow completes successfully, your application will be deployed to Azure Container Apps.

- **Frontend URL**: `https://frontend-traffic-prod.whitestone-e7e06cfe.eastus.azurecontainerapps.io`
- **Backend URL**: `https://backend-traffic-prod.whitestone-e7e06cfe.eastus.azurecontainerapps.io`

You can monitor the deployment progress in the "Actions" tab of your GitHub repository.
