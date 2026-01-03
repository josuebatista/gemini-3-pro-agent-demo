# Gemini ADK Agent with Google Search

This document provides a comprehensive guide to this project. It outlines how to build a single agent with access to Google Search as its tool using the Google Agent Development Kit (ADK), interact with it locally using a web UI, and then deploy it to Google Cloud Run to make it globally accessible.

This guide is aligned with the project's structure, `README.md`, and the `adk-agent-deployment-guide-for-google-cloud-run.md` file.

## Project Overview

The purpose of this project is to demonstrate how to build, run, and deploy a simple, yet powerful, AI agent using the Google Agent Development Kit (ADK). This agent is powered by the Gemini 3 Pro model and is equipped with the Google Search Tool, allowing it to answer questions that require up-to-date information from the web.

The project covers the entire development lifecycle, from setting up the local environment and creating the agent to interacting with it through a web interface and deploying it as a containerized application on Google Cloud Run.

## Core Technologies

*   **Python:** The primary programming language for the agent's logic.
*   **Google Agent Development Kit (ADK):** The framework used to build and run the agent.
*   **Gemini 3 Pro:** The large language model powering the agent.
*   **Google Search:** A pre-built tool for the agent to access real-time information.
*   **uv:** A fast Python package installer and resolver, used for local development.
*   **Docker:** For containerizing the application for deployment.
*   **Google Cloud Run:** The platform for deploying and hosting the agent as a scalable web application.

## Local Development

Follow these steps to set up your environment, create the agent, and run it locally.

### Prerequisites

*   **uv:** An extremely fast Python package installer. [Installation guide](https://astral.sh/docs/uv).
*   **Google Cloud SDK (`gcloud` CLI):** Installed and authenticated.
*   **A Google Cloud Project:** With the Gemini API enabled.
*   **A `GOOGLE_API_KEY`:** You can get one from [AI Studio](https://aistudio.google.com).

### Installation & Setup

1.  **Initialize the Project:**
    Initialize a new Python project using `uv`:
    ```bash
    uv init
    ```

2.  **Install Dependencies:**
    Add the necessary Google libraries for ADK and GenAI:
    ```bash
    uv add google-adk google-genai python-dotenv
    ```
    This will update your `pyproject.toml` and install the packages.

3.  **Configure Environment:**
    Create a file named `.env` in the `my_agent` directory and add your Google API key:
    ```
    GOOGLE_API_KEY="YOUR_API_KEY"
    ```
    The `python-dotenv` library will automatically load this key when the agent runs.

4.  **Activate Virtual Environment:**
    Activate the virtual environment created by `uv`:
    ```bash
    source .venv/bin/activate
    # On Windows: .venv\Scripts\activate
    ```

### Running the Agent

You can interact with your agent in two ways:

1.  **Run in the Terminal:**
    For basic interaction and testing, run the agent directly in your terminal:
    ```bash
    adk run my_agent
    ```

2.  **Launch the Web Interface:**
    To interact with your agent via a user-friendly web UI, start the ADK web server:
    ```bash
    adk web --port 8080
    ```
    Open your browser and navigate to `http://127.0.0.1:8080` to chat with your agent.

## Agent Details

The core logic for the agent is defined in `my_agent/agent.py`. It uses `google.adk.agents.Agent` to create an agent named `basic_search_agent`.

*   **Model:** The agent is configured to use the `gemini-3-pro-preview` model.
*   **Instruction:** The agent is given a specific instruction to act as a helpful assistant that uses Google Search for questions requiring current information.
*   **Tool:** The agent's only tool is `google_search`, a pre-built tool from the ADK that allows it to perform Google searches.

## Deployment to Google Cloud Run

The `adk-agent-deployment-guide-for-google-cloud-run.md` file and the `Dockerfile` in this project are specifically configured to handle the requirements of deploying an ADK agent to the read-only file system of Google Cloud Run.

### Deployment Steps

1.  **Build the Container Image:**
    This command uses Google Cloud Build to build the container image using the provided `Dockerfile` and pushes it to your project's Container Registry.
    ```bash
    gcloud builds submit --tag gcr.io/[PROJECT_ID]/adk-agent .
    ```
    *(Replace `[PROJECT_ID]` with your actual Google Cloud Project ID)*

2.  **Deploy to Cloud Run:**
    Deploy the image you just built to Cloud Run. This command also sets the necessary environment variables.
    ```bash
    gcloud run deploy adk-agent \
      --image gcr.io/[PROJECT_ID]/adk-agent \
      --platform managed \
      --region us-central1 \
      --allow-unauthenticated \
      --set-env-vars="GOOGLE_API_KEY=[YOUR_API_KEY],GOOGLE_GENAI_USE_VERTEXAI=False"
    ```
    *(Replace `[PROJECT_ID]` and `[YOUR_API_KEY]` with your actual values)*

### Key Deployment Configurations

*   **`Dockerfile`:** The Dockerfile copies the agent code and uses a startup script (`start.sh`) to move it to the writable `/tmp` directory within the container. This is necessary because ADK needs to write log and session files.
*   **`--host 0.0.0.0`:** The startup script runs `adk web` listening on `0.0.0.0` to accept connections from the Cloud Run load balancer.
*   **`GOOGLE_GENAI_USE_VERTEXAI=False`:** This environment variable forces the GenAI SDK to use your API key for authentication, rather than attempting to use a service account.

## Interacting with the Deployed Agent

Once the deployment is complete, the `gcloud` command will output the URL for your service. You can access this URL in your web browser to interact with your globally accessible Gemini agent.