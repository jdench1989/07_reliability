**On Local**
<!-- Build image and push to docker hub -->
docker buildx build --platform linux/amd64,linux/arm64 \
  -t jackdench/custom-nginx:latest \
  --push .

**On EC2**
<!-- Get currently running docker container id -->
docker ps

<!-- Stop running container -->
docker stop <container_id>

<!-- Delete stopped container -->
docker container prune
y

<!-- Get old image id -->
docker images

<!-- Delete old image -->
docker image rm <image_id>

<!-- Pull new image version from Dockerhub -->
docker pull jackdench/custom-nginx:latest

<!-- Run container from new image -->
docker run -d --name nginx-proxy -p 80:80 jackdench/custom-nginx:latest

**Check container is running**
<!-- Get currently active containers, new container should still be up -->
docker ps 

<!-- Check logs for errors -->
docker logs <container_id>
Look for errors from nginx or docker
last line in logs should say something like "Ready to run" or something like that (can't remember exactly)

<!-- Live logging -->
docker logs -f <container_id>