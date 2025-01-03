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

Alterar a imagem sandbox_image = "registry.k8s.io/pause:3.6" para sandbox_image = "registry.k8s.io/pause:3.10"

Reiniciar o containerd

systemctl restart containerd

Agora sim, começar a criação do cluster

```bash
    kubeadm init --control-plane-endpoint="192-168-122-200.nip.io:6443" --upload-certs --apiserver-advertise-address=192.168.122.101 --pod-network-cidr=10.244.0.0/16
```

Exemplo de comando join para control plane
```bash
kubeadm join 192-168-122-200.nip.io:6443 --token siipbr.bx448jidt0nj69l8 --discovery-token-ca-cert-hash sha256:f14c808de65b0a598971314ebf3e37aa0772873b6a141b18cf44bf2519f6d240 \
        --control-plane --certificate-key 837dd291248e5c444591ca13a822e8b4945fc263465702e0a1d53839a0a29536
```

Executar os comandos para apontar corretamente o client para a api do kluster

```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    export KUBECONFIG=/etc/kubernetes/admin.conf
```

Instalar o plugin de rede 
```bash
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```


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


Escalar o coredns para os 3 nodes
```bash
kubectl scale deployment coredns --replicas=4 -n kube-system
```

Todo nó do control plane em um cluster Kubernetes possui, por padrão, um taint com a regra NoSchedule. Esse taint impede que workloads comuns, como Pods de aplicativos, sejam agendadas nesses nós.

O objetivo principal dessa regra é garantir que os recursos do control plane fiquem disponíveis exclusivamente para os componentes críticos que gerenciam o cluster, como:

kube-apiserver: Gerencia a comunicação entre os componentes do Kubernetes.
kube-scheduler: Responsável por agendar Pods nos nós.
kube-controller-manager: Garante que o estado desejado do cluster seja mantido.
etcd: Banco de dados que armazena o estado do cluster.
Esses serviços são essenciais para o funcionamento do Kubernetes, e qualquer interferência ou sobrecarga nos recursos do control plane pode comprometer o gerenciamento do cluster. Por isso, em ambientes de produção, é fundamental manter esse isolamento para garantir a estabilidade e confiabilidade da infraestrutura.

No entanto, como estamos configurando um cluster em um ambiente de laboratório, onde a separação rígida de funções não é uma prioridade, podemos remover o taint NoSchedule. Isso permitirá que os nós do control plane também sejam utilizados para executar workloads de usuário, maximizando o uso dos recursos disponíveis no cluster.

```bash
    kubectl taint nodes kubernetes1 node-role.kubernetes.io/control-plane:NoSchedule-
    kubectl taint nodes kubernetes2 node-role.kubernetes.io/control-plane:NoSchedule-
    kubectl taint nodes kubernetes3 node-role.kubernetes.io/control-plane:NoSchedule-
```

```bash
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
```

```bash
    nano ipaddresspool.yaml
```

```bash
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.122.200-192.168.122.200
```

```bash
nano l2advertisement.yaml
```

```bash
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
```

```bash
    kubectl apply -f ipaddresspool.yaml
    kubectl apply -f l2advertisement.yaml
```

Instalar o Ingress do nginx

```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/main/deploy/static/provider/baremetal/deploy.yaml
```
```bash
    kubectl scale deployment ingress-nginx-controller --replicas=4 -n ingress-nginx
```


Deplois de fazer o deploy do apache


Caso tenha problemas checar o campo #Ingress Class#
```bash
root@kubernetes3:~# kubectl describe ingress apache-ingress
Name:             apache-ingress
Labels:           <none>
Namespace:        default
Address:          192.168.122.101,192.168.122.102,192.168.122.103
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host                           Path  Backends
  ----                           ----  --------
  apache.192-168-122-200.nip.io  
                                 /   apache-service:80 (10.244.1.6:80,10.244.2.6:80,10.244.0.6:80)
Annotations:                     nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age                    From                      Message
  ----    ------  ----                   ----                      -------
  Normal  Sync    3m12s (x2 over 3m44s)  nginx-ingress-controller  Scheduled for sync
  Normal  Sync    3m12s (x2 over 3m44s)  nginx-ingress-controller  Scheduled for sync
  Normal  Sync    3m12s (x2 over 3m44s)  nginx-ingress-controller  Scheduled for sync
```
Para editar
```bash
kubectl edit ingress apache-ingress
```
Adicionar abaixo do spec:
```bash
  ingressClassName: nginx
```


URL para acessar o serviço

apache.192-168-122-200.nip.io



Adicionar um novo control plane ao cluster

```bash
  kubeadm join 192-168-122-200.nip.io:6443 --token 14nykf.52mzhryo46s1f02m \
      --discovery-token-ca-cert-hash sha256:92962c3142edb06fbdcd17bad19405757d53fed9ef59a48e9952306df5f4ebdd \
      --control-plane --certificate-key 71267029a4abc8bf8c9071c04d18b2eb6766f27bd4b5a697355aa8f69980f47e
```

Para gerar o Token
```bash
  kubeadm token create --print-join-command
```

Para ver o certificate key

```bash
  kubeadm init phase upload-certs --upload-certs
```




## Backup e Restauração ##

Apontar os certificados e host etcd do kubernetes
```bash
  export ETCDCTL_API=3
  export ETCDCTL_ENDPOINTS="https://localhost:2379"
  export ETCDCTL_CACERT="/etc/kubernetes/pki/etcd/ca.crt"
  export ETCDCTL_CERT="/etc/kubernetes/pki/etcd/server.crt"
  export ETCDCTL_KEY="/etc/kubernetes/pki/etcd/server.key"
```

Verificar saúde do etcd local
```bash
  etcdctl endpoint status --write-out=table
```

Realizar o backup

```bash
  etcdctl snapshot save backup_cluster.db
```

Checar o backup

```bash
  etcdctl snapshot status backup_cluster.db --write-out=table
```

```bash
  etcdctl snapshot restore backup_cluster.db \
  --data-dir /var/lib/etcd
```