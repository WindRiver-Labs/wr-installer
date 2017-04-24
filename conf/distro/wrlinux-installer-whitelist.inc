
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
    python-dbus \
    python-pyparted \
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
