How to setup RSA key for linux server

Reference:
https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server

1. Generate RSA key on your local client 
ssh-keygen
This command will generate a pair of private key and public key 

2. Upload the public key to the remote server.
ssh-copy-id -p port_number user@host


