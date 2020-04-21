# ps2s

PS2S – PowerShell Publish Setup Script helps to automate setup process of locally published projects from developer’s environment to test/production.

In my case developer’s environment is Windows 10, where developers create .NET Core applications with Visual Studio and test its locally; test/production environment is Centos 7 (Linux server, Linux), where developed projects are running as Linux services.

Thus, the standard process of setup locally published projects includes following steps:
1. Stop Linux service which associate with published project
2. Backup files of the project in Linux
3. Copy files of publish from Windows to Linux over SSH with third party software
4. Run stopped Linux service (1)

My script helps to automate these steps. The script **run.ps1** includes following steps:
1. Read **config.json** file, where described source and destination workspaces
2. Check opportunity to work over SSH
3. Detect which projects should be updated – option «Enable»
4. Create **zip** archive of the locally published project
5. Stop Linux service
6. In Linux create backup of the project to specified in config folder with **tar**
7. Using **scp** (secure copy) copy the archive (4) to specified Linux folder
8. **Unzip** with overwrite copied archive to project’s folder in Linux
9. Run Linux service (5)
10.	Ensure that service is running


**Important!**
1. Be careful with **slashes** in config file
2. For running steps 2, 5-10 the **SSH** should be turn on on Windows and Linux machines
3. The **scp** utility (7) requires a password for user when you try to connect to remote machine. But you can [setup](https://unix.stackexchange.com/a/182488/407733) yours’s workspaces to avoid this.
      - In Windows cmd use **ssh-keygen** for creating pair of rsa private/public keys. Some times press Enter. As result in directory C:\Users\\<username\>\\.ssh should be created 2 files: id_rsa and id_rsa.pub.
      - Register public key in Linux
           - Create directory **~/.ssh**  (if it not exists) and copy there **id_rsa.pub**
           - Create file **~/.ssh/authorized_keys** (if it not exists)
           - Append to end to authorized_keys content of **id_rsa.pub**
