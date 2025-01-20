# Use an official Zig image as the base
FROM dotdot0/zig:latest

# Set the working directory in the container
WORKDIR /app

# Copy all project files into the container
# Copy only the src directory into the container
COPY ./src /app/src

# Copy the benchmark.sh script
COPY ./benchmark.sh /app/


# Make the benchmark script executable
RUN chmod +x /app/benchmark.sh

# Build the Zig project
RUN zig build-exe /app/src/benchmark.zig

# Default command to run your benchmark script
CMD ["./benchmark.sh"]