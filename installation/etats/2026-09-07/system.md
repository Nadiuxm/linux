# État du système

Capturé le 2026-09-07 à 12:33 par `bin/snapshot.sh`.

## Distribution
```
ID=fedora
VERSION_ID=44
PRETTY_NAME="Fedora Linux 44 (Forty Four)"
Noyau        : 7.1.13-200.fc44.x86_64
Architecture : x86_64
Paquets      : dnf
```

## Environnement de bureau
```
Bureau  : Hyprland
Session : wayland
Hyprland 0.56.2 built from branch unknown at commit efb50993780079460b0cbed1363e2166a2de1d9f unknown (unknown).
Shell   : /bin/bash
```

## Matériel
```
Machine : Dell Inc. Dell Pro Slim QCS1250
Architecture:                            x86_64
CPU(s):                                  20
Model name:                              Intel(R) Core(TM) i5-14500
CPU(s) scaling MHz:                      35%
RAM     : 15Gi
```

## Stockage
```
NAME                                            SIZE FSTYPE      MOUNTPOINT
sda                                           232,9G             
├─sda1                                          600M vfat        
├─sda2                                            2G ext4        
└─sda3                                        230,3G btrfs       /mnt/ancien-home
zram0                                             8G swap        [SWAP]
nvme0n1                                       238,5G             
├─nvme0n1p1                                     600M vfat        /boot/efi
├─nvme0n1p2                                       2G ext4        /boot
└─nvme0n1p3                                   235,9G crypto_LUKS 
  └─luks-680cb146-2018-49f5-b166-c4ecec3dfe26 235,9G btrfs       /home

Sys. de fichiers Type  Taille Utilisé Dispo Uti% Monté sur
/dev/dm-0        btrfs   236G     56G  179G  24% /
/dev/dm-0        btrfs   236G     56G  179G  24% /home
/dev/nvme0n1p2   ext4    2,0G    318M  1,5G  18% /boot
/dev/nvme0n1p1   vfat    599M    7,9M  591M   2% /boot/efi
/dev/sda3        btrfs   231G     50G  181G  22% /mnt/ancien
/dev/sda3        btrfs   231G     50G  181G  22% /mnt/ancien-home
```

## Sécurité
```
SELinux  : Enforcing
Pare-feu : firewalld (active)
Chiffrement : 1 volume(s) LUKS
   Secure Boot: enabled (deployed)
  TPM2 Support: yes
```
