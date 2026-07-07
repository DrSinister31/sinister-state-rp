FROM python:3.11-slim

WORKDIR /app

# Copy the backend code
COPY DiscordBot/bot ./bot
COPY DiscordBot/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose any needed ports (if you have an HTTP API; modify as needed)
EXPOSE 56556

# Command to run the bot
CMD ["python", "bot/main.py"]
