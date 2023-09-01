Repositório para facilitar meus testes com aplicações e protocolos






Nas distribuições Ubuntu, o SELinux é aplicado pelo qemu, mesmo que esteja desabilitado globalmente, isso pode causar algo inesperado. Não foi possível abrir '/var/lib/libvirt/images/<FILE_NAME>': Erros de permissão negada. Verifique novamente se security_driver = "none" não foi comentado em /etc/libvirt/qemu.conf e emita sudo systemctl restart libvirt-bin para reiniciar o daemon.