Quick Setup
1. **Install Docker and Docker-Compose**
- [Docker Install documentation](https://docs.docker.com/get-docker/)
- [Docker-Compose Install documentation](https://docs.docker.com/compose/install/)
2. **Create a docker-compose.yml files similar to this**
```yaml
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
```
This is the bare minimum configuration required. See the [documentation](https://nginxproxymanager.com/setup/) for more.
3. **Run the Docker-Compose**
```bash
docker-compose up -d

# If using docker-compose-plugin
docker compose up -d
```
4. **Access the web UI**
- Open your web browser and navigate to `http://localhost`, 
- When your docker container is running, connect to it on port 81 for the admin interface. Sometimes this can take a little bit because of the entropy of keys.
`http://127.0.0.1:81`

Default credentials:
```bash
Email:    admin@example.com
Password: changeme
```
[Nginx-proxy-manger site](https://nginxproxymanager.com/)

Note:
- You can add SSL certificates for your domain names using Let's Encrypt.
- You can also add and configure multiple Nginx Proxy Manager instances using Docker Swarm or Kubernetes.

