# Setup
1. Put your `id_rsa` in the `auth` folder
2. Enter your VPS IP in `config.env.example`, then rename it to `config.env`
3. Add authorized users with `sudo ./auth/manage.sh`
4. Add the `danted` user: `sudo adduser --system --no-create-home --shell /usr/sbin/nologin danted`
5. On the VPS, add the following to `/etc/ssh/sshd_config`
    ```sshconfig
    GatewayPorts yes
    AllowTcpForwarding yes
    ```
   Then restart the SSH service:
   `sudo systemctl restart ssh` (Red Hat: `sudo systemctl restart sshd`)
6. Start with `sudo ./run.sh`
