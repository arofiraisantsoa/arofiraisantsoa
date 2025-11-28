https://sleeplessbeastie.eu/2019/08/12/how-to-perform-suite-change/
https://docs.openstack.org/ocata/fr/install-guide-debian/environment.html

# Projet Infrastructure as Code.
https://www.youtube.com/watch?v=yJcW5xS6k1g&list=PLHilVoTkxy-DdW6QN_NRVwuBTqZcJgaIK
https://www.informaticar.net/how-to-install-openstack-on-centos/
ae6d2544e30543ce
https://docs.openstack.org/install-guide/launch-instance-selfservice.html
https://linuxconfig.org/how-to-resize-ext4-root-partition-live-without-umount
https://openstack.goffinet.org/07-00-administration-openstack-2
https://eazytraining.fr/mise-en-place-dun-systeme-de-stockage-distribue-haute-disponibilite-cas-de-ceph-via-ansible/
https://intuitive.cloud/blog/multi-node-openstack-newton-with-ceph-as-storage
https://contactchanaka.medium.com/mastering-openstack-from-installation-to-auto-scaling-your-cloud-infrastructure-1bb05d422b16
https://mandem.medium.com/installation-dun-cluster-multi-noeuds-openstack-victoria-sur-des-serveurs-d%C3%A9di%C3%A9s-avec-le-backend-5ed332eeeaee
https://docs.openstack.org/openstack-ansible/ussuri/admin/scale-environment.html
https://docs.redhat.com/en/documentation/red_hat_openstack_platform/17.1/html/deploying_red_hat_ceph_storage_and_red_hat_openstack_platform_together_with_director/assembly_scaling-the-ceph-storage-cluster_deployingcontainerizedrhcs#proc_scaling-up-the-ceph-storage-cluster_assembly_scaling-the-ceph-storage-cluster
https://docs.napatech.com/r/Getting-Started-with-Napatech-Link-VirtualizationTM-Software/MTU-Configuration

https://conf-ng.jres.org/2015/document_revision_1425.html?download


http://audaces.asso.st/uploads/Presentations/crri_audaces_2014.pdf

https://cyber.gouv.fr/sites/default/files/document/anssi-guide-openstack_v1-0.pdf

# Projet E-reputation
https://www.appvizer.fr/marketing/gestion-reputation
https://smartkeyword.io/seo-outils-google-google-alerts/




winrm quickconfig -q
winrm set winrm/config/service/Auth @{Kerberos="true"; Negotiate="true"}
winrm set winrm/config/service @{AllowUnencrypted="true"}
Restart-Service WinRM.


📘 Guide Ansible + WinRM Kerberos

1️⃣ Prérequis côté serveur Windows
	• OS : Windows Server 2016/2019/2022
	• Compte AD avec Domain Admins ou permissions WinRM correctes
	• SPN configuré pour le serveur WinRM
a) Vérifier / créer le listener HTTP (5985)

# Vérifier les listeners existants
winrm enumerate winrm/config/listener
# Créer un listener HTTP si nécessaire
winrm create winrm/config/Listener?Address=*+Transport=HTTP
b) Configurer le service WinRM pour HTTP Kerberos

# Configurer l'authentification Kerberos + Negotiate
winrm set winrm/config/service/Auth @{Kerberos="true"; Negotiate="true"}
# Autoriser la connexion non chiffrée (nécessaire pour HTTP)
winrm set winrm/config/service @{AllowUnencrypted="true"}
# Redémarrer le service WinRM
Restart-Service WinRM
💡 Pour HTTPS (port 5986), vous n’aurez pas besoin d’AllowUnencrypted=true mais il faut un certificat valide.

c) Configurer le listener HTTPS (5986, optionnel mais recommandé pour prod)

# Lister les certificats pour identifier le Thumbprint
Get-ChildItem -Path Cert:\LocalMachine\My
# Créer un listener HTTPS
winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{
    Hostname="SVW034ADDCP1.ad.intra";
    CertificateThumbprint="0492F610338921274E73B3C6C059C21B004848CE"
} ou 
# Ouvrir PowerShell en administrateur
New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint 0492F610338921274E73B3C6C059C21B004848CE -Force
	• Vérifiez avec :

winrm enumerate winrm/config/listener

d) Vérifier RootSDDL (permissions)

winrm get winrm/config/service
	• Assurez-vous que RootSDDL permet à votre compte de se connecter :

(A;;GA;;;BA)  → Full access pour Domain Admins
(A;;GR;;;IU)  → Read pour Interactive Users


2️⃣ Tester Kerberos côté serveur

# Afficher les tickets Kerberos pour votre compte
klist
	• Vérifiez que le ticket pour le SPN HTTP/SVW034ADDCP1.ad.intra existe.

3️⃣ Configuration côté Linux / Ansible
a) Installer les dépendances

# Pywinrm pour Ansible
pip3 install --upgrade pywinrm requests-kerberos
	• Vérifiez la version :

pip3 show pywinrm
# Version >= 0.5.0

b) Configuration Kerberos (/etc/krb5.conf)

[libdefaults]
    default_realm = AD.INTRA
    dns_lookup_realm = true
    dns_lookup_kdc = true
    rdns = false
    forwardable = true
    ticket_lifetime = 24h
    renew_lifetime = 7d
[realms]
    AD.INTRA = {
        kdc = 10.240.200.22
        kdc = 10.240.100.30
        kdc = 192.168.2.150
        admin_server = 10.240.200.22
    }
[domain_realm]
    .ad.intra = AD.INTRA
    ad.intra = AD.INTRA
	• Testez la connexion Kerberos :

kinit gestdomja@AD.INTRA
kvno HTTP/SVW034ADDCP1.ad.intra

c) Inventory Ansible
HTTP (5985, test / dev)

SVW034ADDCP1.ad.intra
[all:vars]
ansible_connection: winrm
ansible_winrm_transport: kerberos
ansible_winrm_scheme: http
ansible_winrm_port: 5985
ansible_winrm_server_cert_validation: ignore
ansible_winrm_kinit_mode: managed
ansible_user: gestdomja@AD.INTRA
ansible_password: 'VOTRE_MOT_DE_PASSE'
ansible_winrm_pipelining: false
HTTPS (5986, prod sécurisé)

SVW034ADDCP1.ad.intra
[all:vars]
ansible_connection: winrm
ansible_winrm_transport: kerberos
ansible_winrm_scheme: https
ansible_winrm_port: 5986
ansible_winrm_server_cert_validation: ignore
ansible_winrm_kinit_mode: managed
ansible_user: gestdomja@AD.INTRA
ansible_password: 'VOTRE_MOT_DE_PASSE'
ansible_winrm_pipelining: false

d) Test Ansible

ansible -i hosts SVW034ADDCP1.ad.intra -m win_ping -vvv
	• Vous devriez obtenir SUCCESS si tout est correctement configuré.




RUNDECK TOKEN=
61iKYCe2tXYJ53SoxOcpJeyu1f6ygG4g

À partir de l’adresse <https://rundeck.ofb.fr/user/profile> 


1️⃣ Principe
	• GitLab déclenche le job Rundeck via l’API.
	• Récupère l’execution ID du job lancé.
	• Interroge périodiquement l’API Rundeck pour vérifier l’état (running, succeeded, failed).
	• Échoue le job GitLab si le job Rundeck échoue.

2️⃣ Exemple .gitlab-ci.yml complet

stages:
  - deploy
rundeck_deploy:
  stage: deploy
  image: curlimages/curl:latest
  variables:
    RUNDECK_URL: "https://rundeck.ofb.fr/"
    RUNDECK_JOB_ID: "6f50a0a3-3e3c-4356-9baf-d866429e6b2e"
    ENVIRONMENT: "ANSIBLE-PROD"
    CHECK_INTERVAL: 10   # secondes entre chaque check
    MAX_CHECKS: 60       # nombre max de vérifications (60*10s = 10 min)
  script:
    - echo "Déclenchement du job Rundeck..."
    - >
      RESPONSE=$(curl -s -X POST "$RUNDECK_URL/api/36/job/$RUNDECK_JOB_ID/run"
      -H "X-Rundeck-Auth-Token: $RUNDECK_TOKEN"
      -H "Content-Type: application/json"
      -d "{\"options\":{\"env\":\"$ENVIRONMENT\"}}")
    - EXEC_ID=$(echo $RESPONSE | jq -r '.id')
    - echo "Job Rundeck lancé avec Execution ID: $EXEC_ID"
# Boucle pour vérifier le statut
    - |
      STATUS="running"
      COUNT=0
      while [[ "$STATUS" == "running" ]] && [ $COUNT -lt $MAX_CHECKS ]; do
        sleep $CHECK_INTERVAL
        STATUS=$(curl -s -H "X-Rundeck-Auth-Token: $RUNDECK_TOKEN" \
          "$RUNDECK_URL/api/36/execution/$EXEC_ID" | jq -r '.status')
        echo "Statut actuel : $STATUS"
        COUNT=$((COUNT+1))
      done
# Échec si le job Rundeck a échoué
    - |
      if [[ "$STATUS" != "succeeded" ]]; then
        echo "Le job Rundeck a échoué avec le statut : $STATUS"
        exit 1
      else
        echo "Le job Rundeck a réussi !"
      fi
  only:
    - main


<img width="730" height="3524" alt="image" src="https://github.com/user-attachments/assets/10e3d616-8742-4c52-8d94-409a809937f9" />

