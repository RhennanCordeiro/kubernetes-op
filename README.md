## Repositório de Testes para Aplicações e Protocolos em Ambientes Kubernetes

Este repositório fornece um ambiente de testes completo e configurável para experimentar com diferentes aplicações e protocolos em clusters Kubernetes. Ele inclui scripts e configurações pré-configurados para facilitar a criação e gerenciamento de clusters, além de exemplos práticos de uso.

### Pré-requisitos
* **Terraform:** https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
* **Docker:** https://docs.docker.com/get-docker/
* **kubectl:** https://kubernetes.io/docs/tasks/tools/install-kubectl/


Nas distribuições Ubuntu, o SELinux é aplicado pelo QEMU, mesmo quando está desabilitado globalmente, o que pode resultar em comportamentos inesperados.

O erro "Não foi possível abrir '/var/lib/libvirt/images/<FILE_NAME>': Permissão negada" pode ocorrer devido a isso.

Para resolver, verifique se a linha security_driver = "none" não está comentada no arquivo /etc/libvirt/qemu.conf. Em seguida, execute o comando sudo systemctl restart libvirtd para reiniciar o daemon do libvirt.




## Para Subir o clustes kubernetes

### Preparar o containerd para o kubernetes

```bash
    sudo containerd config default| sudo tee /etc/containerd/config.toml
```

Alterar o SystemdCgroup de false para true

Reiniciar o containerd

systemctl restart containerd

Agora sim, começar a criação do cluster

```bash
kubeadm init --control-plane-endpoint="192-168-122-200.nip.io:6443" --upload-certs --apiserver-advertise-address=192.168.122.101 --pod-network-cidr=10.244.0.0/16
```

Executar os comandos para apontar corretamente o client para a api do kluster

```bash
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  export KUBECONFIG=/etc/kubernetes/admin.conf
```

Instalar o plugin de rede 

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


Resultado final do primeiro node e control plane

root@kubernetes1:~# kubectl get pods -A
NAMESPACE      NAME                                  READY   STATUS    RESTARTS   AGE
kube-flannel   kube-flannel-ds-q2ghz                 1/1     Running   0          40s
kube-system    coredns-668d6bf9bc-26w86              1/1     Running   0          2m13s
kube-system    coredns-668d6bf9bc-6xttk              1/1     Running   0          2m13s
kube-system    etcd-kubernetes1                      1/1     Running   0          2m18s
kube-system    kube-apiserver-kubernetes1            1/1     Running   0          2m18s
kube-system    kube-controller-manager-kubernetes1   1/1     Running   0          2m19s
kube-system    kube-proxy-tr9ld                      1/1     Running   0          2m13s
kube-system    kube-scheduler-kubernetes1            1/1     Running   0          2m18s


O kubernetes só aceita load balancer, quando tem algum plugin cloud, porém tenho que fazer ele rodar em base metal com o IP que eu quero

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

nano ipaddresspool.yaml

apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.122.200-192.168.122.200

nano l2advertisement.yaml

apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool

kubectl apply -f ipaddresspool.yaml
kubectl apply -f l2advertisement.yaml


Cluster Puro
apache.192-168-122-200.nip.io

