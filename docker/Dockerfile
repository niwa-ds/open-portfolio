# Use lightweight Python 3.11 base image
FROM python:3.11-slim

# Set Python environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
	PYTHONUNBUFFERED=1 \
	PYTHONUTF8=1 \
	PYTHONIOENCODING=utf-8

# Set working directory inside the container
WORKDIR /workspace

# Install required system packages (build tools & Japanese fonts)
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	git \
	sudo \
	curl \
	sqlite3 \
	fonts-ipafont-gothic \
	fonts-ipafont-mincho \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Install project package & dependencies
COPY pyproject.toml .
COPY README.md .
COPY src/ ./src

RUN pip install --upgrade pip && pip install --no-cache-dir -e ".[dev,notebook]"


# Set default font for matplotlib (japanese font)
RUN mkdir -p /root/.config/matplotlib && \
	echo "font.family: IPAGothic" > /root/.config/matplotlib/matplotlibrc

# Expose JupyterLab port
EXPOSE 8888

# Launch JupyterLab (no token for local development)
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--NotebookApp.token=", "--allow-root"]

