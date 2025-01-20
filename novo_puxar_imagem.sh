#!/bin/bash

# Verifica se está sendo executado como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script deve ser executado como root."
    exit 1
fi

echo "== RESTAURAÇÃO DE IMAGEM PARA DISCO =="

# Solicita o pendrive com a imagem
echo "Pendrives disponíveis:"
lsblk -d -o NAME,SIZE,TYPE | grep "disk"
read -p "Informe o nome do pendrive onde está a imagem (exemplo: sdb): " pendrive

# Verifica se o pendrive existe
if [[ ! -b /dev/$pendrive ]]; then
    echo "Pendrive /dev/$pendrive não encontrado."
    exit 1
fi

# Monta o pendrive se necessário
mountpoint=$(lsblk -o MOUNTPOINT -n /dev/$pendrive | grep -v "^$")
if [[ -z "$mountpoint" ]]; then
    mountpoint="/mnt/pendrive"
    mkdir -p $mountpoint
    mount /dev/${pendrive}1 $mountpoint
fi

# Lista as imagens disponíveis
echo "Imagens disponíveis no pendrive:"
ls $mountpoint/*.img
read -p "Informe o nome completo da imagem para restaurar: " imagem

# Verifica se a imagem existe
if [[ ! -f $mountpoint/$imagem ]]; then
    echo "Imagem $imagem não encontrada no pendrive."
    umount $mountpoint
    exit 1
fi

# Solicita o disco de destino
echo "Discos disponíveis:"
lsblk -d -o NAME,SIZE,TYPE | grep "disk"
read -p "Informe o nome do disco de destino (exemplo: sda): " destino

# Verifica se o disco existe
if [[ ! -b /dev/$destino ]]; then
    echo "Disco /dev/$destino não encontrado."
    umount $mountpoint
    exit 1
fi

# Confirma antes de continuar
echo "A imagem $imagem será restaurada em /dev/$destino. TODOS OS DADOS NO DESTINO SERÃO PERDIDOS!"
read -p "Deseja continuar? (s/n): " confirm
if [[ $confirm != "s" ]]; then
    echo "Operação cancelada."
    umount $mountpoint
    exit 1
fi

# Restaura a imagem usando dd
echo "Restaurando a imagem para o disco..."
dd if=$mountpoint/$imagem of=/dev/$destino bs=4M status=progress

# Verifica se houve sucesso
if [[ $? -eq 0 ]]; then
    echo "Imagem restaurada com sucesso em /dev/$destino."
else
    echo "Falha ao restaurar a imagem."
fi

# Desmonta o pendrive
umount $mountpoint

echo "Processo concluído."
