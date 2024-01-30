FROM python:3.8-slim

# Set up the application directory
WORKDIR /app

# Install Poetry
RUN pip install poetry

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=0 \
    POETRY_VIRTUALENVS_CREATE=0 \
    POETRY_NO_CACHE=1

# Copy the requirements file
COPY pyproject.toml poetry.lock /app/

# Install dependencies
RUN poetry install

# Copy the application files with appropriate permissions
COPY . /app

# Expose the port the app runs on
EXPOSE 8000

# Start gunicorn with a variable number of workers
CMD gunicorn -b 0.0.0.0:8000 gunicorn_k8s_test:app --workers ${WORKERS:-2}
