# Codjixd

**Codjixd** is a lightweight and flexible service manager for Linux systems and Docker containers.

## Features

- **Start, Stop, Restart**: Manage services with simple commands.
- **Status, List**: Simple metrics-like status, list all services.
- **Defination, Configs**: Easy to define and configure services.
- **Dependency Management**: Automatically start dependent services.
- **Health Checks**: Define custom health checks for services.
- **Log Rotation**: Automatically rotate logs for better management.
- **Run anywhere**: As a plain script it can run on any Linux system.

## Installation

### Requirements

- It requires `bash` to run. Make sure you have it installed.
- On busybox-based systems, you need to install the full:
  - `procps` it is required to work properly.
  - `less` it is optional to get live logs.

```bash
apk add bash procps less
```

### Shell Script

```bash
# 1. Get the script:
wget https://dub.sh/codjixd -O codjixd.sh
# 2. Make it executable:
chmod +x codjixd.sh
# 3. Add script to $PATH:
sudo mv codjixd.sh /usr/bin/codjixd
# 4. Final setup:
mkdir -p /opt/codjixd/services
sudo chown -R $USER /opt/codjixd
```

### Docker Image

```bash
docker pull codjix/codjixd:latest
```

## Usage

```
Usage: codjixd <command> [<service>]
Commands:
  start <service>    Start a service
  stop <service>     Stop a service
  restart <service>  Restart a service
  kill <service>     Kill a service and its dependencies
  status <service>   Show status and metrics for a service
  logs <service>     Tail logs for a service
  list, ls           List all available services
  version            Show version information
  help               Show this help message
Options:
  -v, --version      Show version information
  -h, --help         Show this help message
```

## Configuration

Codjixd uses a configuration file located at `/etc/codjixd.conf`. You can customize the following variables:

```ini
BASE_DIR="/opt/codjixd"       # Base directory for logs, PIDs, and services
LOG_DIR="$BASE_DIR/logs"      # Directory for service logs
PID_DIR="$BASE_DIR/pids"      # Directory for PID files
SERVICES_DIR="$BASE_DIR/services"  # Directory for service scripts
```

## Service Definition

To create a service for Codjixd, follow these steps:

1. Create a Service Script:

   - Place your service script in the `services` directory (default: /opt/codjixd/services).
   - `Serivce name` is considered as the script name without ".sh" extension so keep it simple.
   - The script must has a `start_fn` function, which contains the logic to start the service.
   - Optionally, you can define a `health_check` function for custom health checks and a `depend_on` array for service dependencies.

2. Example Service Script:

```bash
#!/bin/bash

# Dependencies (optional)
depend_on=("service_1" "service_2" "service_3")

# Start function (required)
# This function should run as a daemon(does not exit)
start_fn() {
    echo "Starting my_service..."
    # Add your service start logic here
    while true; do
        echo "my_service is running..."
        sleep 10
    done
}

# Health check function (optional)
health_check() {
    # Add your health check logic here
    if curl -s http://localhost:8080/health > /dev/null; then
        return 0
    else
        return 1
    fi
}
```

## Contributing

Contributions are welcome! Please read the [Contributing Guidelines](./CONTRIBUTING.md) for details.

## License

Codjixd is licensed under the MIT License. See [LICENSE](./LICENSE) for more details.
