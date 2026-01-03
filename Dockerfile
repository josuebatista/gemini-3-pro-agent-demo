FROM python:3.11-slim

ENV PYTHONUNBUFFERED=True

WORKDIR /app

# Install dependencies
COPY my_agent/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the agent code to /app/my_agent
COPY my_agent /app/my_agent

# Create a startup script
# 1. Create a parent 'agents' directory in /tmp
# 2. Copy 'my_agent' folder INTO /tmp/agents/ (preserving the folder name)
# 3. Run adk web from the parent directory
RUN echo '#!/bin/bash\n\
mkdir -p /tmp/agents\n\
cp -r /app/my_agent /tmp/agents/\n\
cd /tmp/agents\n\
echo "Starting ADK Web in $(pwd)..."\n\
exec adk web --host 0.0.0.0 --port $PORT\n\
' > /start.sh && chmod +x /start.sh

# Use the script as the container entrypoint
CMD ["/start.sh"]