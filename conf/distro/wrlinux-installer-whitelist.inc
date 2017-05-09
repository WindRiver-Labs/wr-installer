
# Whitelist for meta-openembedded/meta-gnome
PNWHITELIST_gnome-layer += "\
    gnome-themes \
    gtk-engines \
    libgnomecanvas \
    libgnome-keyring \
    libxklavier \
    network-manager-applet \
"

# Whitelist for meta-openembedded/meta-python
PNWHITELIST_meta-python += "\
    python3-certifi \
    python3-cffi \
    python3-cryptography \
    python3-dbus \
    python3-idna \
    python3-ndg-httpsclient \
    python3-pyasn1 \
    python3-pycparser \
    python3-pyopenssl \
    python3-pyparted \
    python3-pysocks \
    python3-pytz \
    python3-pyudev \
    python3-requests \
    python3-urllib3 \
    python-pyrex-native \
    python-six \
"

# Whitelist for meta-openembedded/meta-filesystems
PNWHITELIST_filesystems-layer += "\
    ntfs-3g-ntfsprogs \
"

# Whitelist for meta-openembedded/meta-oe
PNWHITELIST_openembedded-layer += "\
    fltk \
    fontforge \
    giflib \
    libndp \
    libvncserver \
    mozjs \
    networkmanager \
    polkit \
    python-pygobject \
    ttf-abyssinica \
    ttf-dejavu \
    ttf-lklug \
    ttf-lohit \
    ttf-sazanami \
    ttf-wqy-zenhei \
    ttf-tlwg \
    uthash \
    x11vnc \
"
