FROM condaforge/miniforge3

# Install necessary tools
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    python3-pip \
    pipx \
    iverilog

# Install Python packages
RUN pipx install pylint black pytest numpy ipykernel

# Set working directory
WORKDIR /workspace