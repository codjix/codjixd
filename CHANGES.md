# Changelog

<details open>
  <summary> 1.0.2 - 2025/01/27</summary>

- `New` Ability to view old logs with the `logs` command.
- `New` Separate live logs method with the `logs` command.
- `New` Ability to delete logs with the `logs` command.

</details>

<details>
  <summary> 1.0.1 - 2025/01/11</summary>

- `New` Docker image for Codjixd.
- `New` Kill command to stop services and their dependencies recursively.
- `New` New alias: `ls` for the `list` command.
- `Fix` Each dependency has its own session now, to allow stopping the optional dependencies withowt affecting the main process tree.
- `Fix` Health check loop is delayed 5 seconds by default to avoid high CPU usage.
- `Fix` Health check logs are directed to logs file.
- `Fix` Major update to the logs command and enable the access to old logs.

</details>
