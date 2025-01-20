#!/bin/bash

# Verifica se está sendo executado como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script deve ser executado como root."
    exit 1
fi

echo "== CRIAÇÃO DE IMAGEM DO DISCO =="

# Lista os discos disponíveis
echo "Discos disponíveis:"
lsblk -d -o NAME,SIZE,TYPE | grep "disk"

# Solicita o disco de origem
read -p "Informe o nome do disco de origem (exemplo: sda): " origem

# Verifica se o disco existe
if [[ ! -b /dev/$origem ]]; then
    echo "Disco /dev/$origem não encontrado."
    exit 1
fi

# Solicita o pendrive de destino
echo "Pendrives disponíveis:"
lsblk -d -o NAME,SIZE,TYPE | grep "disk"
read -p "Informe o nome do pendrive onde será salva a imagem (exemplo: sdb): " pendrive

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

# Define o caminho da imagem
imagem="$mountpoint/disk_image_$(date +%Y%m%d%H%M%S).img"

# Confirma antes de continuar
echo "A imagem será salva em: $imagem"
read -p "Deseja continuar? (s/n): " confirm
if [[ $confirm != "s" ]]; then
    echo "Operação cancelada."
    umount $mountpoint
    exit 1
fi

# Cria a imagem usando dd
echo "Criando a imagem do disco..."
dd if=/dev/$origem of=$imagem bs=4M status=progress

# Verifica se houve sucesso
if [[ $? -eq 0 ]]; then
    echo "Imagem criada com sucesso: $imagem"
else
    echo "Falha ao criar a imagem."
fi

# Desmonta o pendrive
umount $mountpoint

echo "Processo concluído."
