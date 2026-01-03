# ADK Agent Deployment Guide for Google Cloud Run
Here is the complete deployment summary for your ADK AI Agent on Google Cloud Run. This approach addresses the read-only file system constraints, network binding requirements, and directory structure needed for the ADK `web` runner.

## 1. Project Structure
Ensure your local project directory looks like this before starting:

```text
/Gemini-3-Pro-AI-Agent
├── Dockerfile                  # The custom Dockerfile (content below)
├── my_agent/                   # Your agent package folder
│   ├── __init__.py
│   ├── agent.py
│   └── requirements.txt
```

## 2. Dockerfile
Create a file named `Dockerfile` (no extension) in the root of your project. This configuration uses a startup script to copy your agent to the writable `/tmp` directory and configures the host/port correctly for Cloud Run.

```dockerfile
# Use an official Python runtime
FROM python:3.11-slim

# Ensure Python logs are output immediately (helps with debugging)
ENV PYTHONUNBUFFERED=True

WORKDIR /app

# 1. Install dependencies
# We copy requirements first to leverage Docker cache layers
COPY my_agent/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. Copy the agent code to a staging area
COPY my_agent /app/my_agent

# 3. Create a startup script
# - Creates a parent directory in /tmp (which is writable in Cloud Run)
# - Copies the 'my_agent' folder there to preserve the structure required by ADK
# - Starts 'adk web' listening on 0.0.0.0 and the Cloud Run injected PORT
RUN echo '#!/bin/bash\n\
mkdir -p /tmp/agents\n\
cp -r /app/my_agent /tmp/agents/\n\
cd /tmp/agents\n\
echo "Starting ADK Web in $(pwd)..."\n\
exec adk web --host 0.0.0.0 --port $PORT\n\
' > /start.sh && chmod +x /start.sh

# 4. Use the script as the container entrypoint
CMD ["/start.sh"]
```

## 3. Build Instructions
Run these commands from your project root (where the `Dockerfile` is located).

### Step A: Build the Container Image
We explicitly build the image first to ensure the `Dockerfile` is used (bypassing automatic Buildpacks).

```bash
gcloud builds submit --tag gcr.io/abcs-test-ai-agent-001/adk-agent .
```
*(Replace `abcs-test-ai-agent-001` with your actual Project ID if different)*

### Step B: Deploy to Cloud Run
Deploy the image you just built.

```bash
gcloud run deploy adk-agent ^
  --image gcr.io/abcs-test-ai-agent-001/adk-agent ^
  --project=abcs-test-ai-agent-001 ^
  --region=us-central1 ^
  --allow-unauthenticated ^
  --set-env-vars="GOOGLE_API_KEY=AIzaSy...,GOOGLE_GENAI_USE_VERTEXAI=False"
```
*(Replace `AIzaSy...` with your actual Google Maps/AI Studio API Key)*

## 4. Key Configuration Details
For future troubleshooting, here is why this specific setup is required:

1.  **`cp -r ... /tmp/agents`**: Cloud Run filesystems are read-only. ADK needs to write artifacts (logs, history) to a `.adk` folder. We copy the code to `/tmp` (which is an in-memory writable filesystem) so ADK can write its data there without crashing.
2.  **`cd /tmp/agents`**: The `adk web` command must be run from the **parent** directory of the agent folder. It scans subdirectories to find agents. If you run it *inside* `my_agent`, it finds nothing.
3.  **`--host 0.0.0.0`**: ADK defaults to `localhost` (127.0.0.1). Cloud Run's load balancer cannot reach localhost. We must listen on all interfaces (`0.0.0.0`).
4.  **`GOOGLE_GENAI_USE_VERTEXAI=False`**: This forces the Google Gen AI SDK to use your API Key (`AIza...`) instead of trying to authenticate via Google Cloud IAM (Service Account), which is the default behavior when running on Google Cloud infrastructure.

## 5. Stopping and Protecting the Cloud Run Service
Since you deployed this on **Cloud Run**, the service behaves differently than a traditional server (VM).

### 1. It "Stops" Itself Automatically (Scale to Zero)
Cloud Run is serverless. If you just close your browser tab and no one accesses the URL, **the container automatically shuts down within a few minutes.**
*   **Cost:** You are not charged for compute time when the service is idle.
*   **Action:** You technically don't *need* to do anything if you just want it to stop billing you for CPU/RAM.

---

However, if you want to **permanently remove it** or **prevent public access**, use one of the following methods:

### 2. Permanently Delete the Service (Clean Up)
If you are done with this test and want to remove the service entirely so the URL stops working and it disappears from your dashboard:

```bash
gcloud run services delete adk-agent ^
  --project=abcs-test-ai-agent-001 ^
  --region=us-central1
```
*   You will be asked to confirm. Type `Y` and press Enter.

### 3. Make it Private (Revoke Public Access)
If you want to keep the service deployed but stop the public (anyone with the URL) from accessing it:

```bash
gcloud run services remove-iam-policy-binding adk-agent ^
  --project=abcs-test-ai-agent-001 ^
  --region=us-central1 ^
  --member=allUsers ^
  --role=roles/run.invoker
```
*   **Result:** The URL will return `403 Forbidden` to anyone trying to access it. You would need to be authenticated via gcloud/IAM to access it again.

### 4. Using the Google Cloud Console (GUI)
1.  Go to the [Cloud Run Console](https://console.cloud.google.com/run).
2.  Select your project (`abcs-test-ai-agent-001`).
3.  Check the box next to **`adk-agent`**.
4.  Click **DELETE** at the top of the page.