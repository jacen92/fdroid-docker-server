Docker image with fdroid server for x64_86 and arm32v7

This project contains an fdroid repository to deploy Android applications based on (https://guardianproject.info/2013/11/05/setting-up-your-own-app-store-with-f-droid/).
With this repository you will be able to build and deploy your own headless fdroid server.
This fdroid server is exposed in the container port 80.

How to build it:

```
mkdir -p /opt/fdroid/config && cp docker/default/auth_template.txt /opt/fdroid/config/auth.txt
cd docker
docker build --rm -t fdroid -f Dockerfile .
docker run --rm -p 8000:80 -p 2222:22 -v /opt/fdroid/config:/opt/config --name fdroid fdroid
```

Customize config:
-----------------

You can customize the configuration file by providing a `config.in.py` file copy in `/opt/config`.


Use with volume:
----------------

You can use this image to store your apk in a volume with `-v /your/persistant/dir:/opt/apk`.
In this way you just have to cp your file in the host directory and the watcher will handle it.


Use with scp:
-------------

Most of us will use this with a CI server to build and upload apk. To do that this image contain an ssh deamon limited to scp.
Note that in this case the volume `/opt/apk` will not be watched for new files and the only way to put apk to this container become with scp.
The ssh deamon is exposed to port 22 and the user is fdroid.
To get access you can use the copy the auth_template.txt file to `/opt/config/auth.txt` with an other password (fdroid:other_password).
You also can provide an authorized_keys file in the same way in `/opt/config`.
At startup the container will set up the ssh deamon then you should be able to scp your file with:

```
scp myapp.apk fdroid@myserver:~/

```
