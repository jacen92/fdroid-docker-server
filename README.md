Docker image with fdroid server for x64_86 and arm32v7

This project contains a fdroid repository to deploy Android applications based on (https://guardianproject.info/2013/11/05/setting-up-your-own-app-store-with-f-droid/).
with this repository you will be able to build and deploy your own fdroid server.


How to build it:
```
cd docker
docker build --rm -t fdroid -f Dockerfile .
# or to build the arm image:
docker build --rm -t fdroid -f Dockerfile.arm .

```

How to use it:
```
cd docker
docker run --rm -d --n fdroid -v $pwd:/opt/apk -p 8031:80 fdroid:latest

```
