-- Hyprland — configuration personnelle
--
-- PRINCIPE, inchangé depuis Sway : le compositeur ne fait que du TUILAGE. Tout
-- ce qui relève du shell — barre, lanceur, fond d'écran, notifications,
-- verrouillage, OSD, capture d'écran, menu de session — appartient à Noctalia.
--
-- POURQUOI CE FICHIER EST EN LUA ET NON EN .conf
-- Hyprland a DÉPRÉCIÉ hyprlang (le format « key = value » de tous les tutoriels)
-- à partir de la version 0.55, au profit d'une API Lua. Le paquet ne livre plus
-- qu'un exemple .lua, et /usr/share/hypr/stubs/hl.meta.lua documente l'API
-- complète — c'est la référence à lire, pas les tutoriels en ligne, qui sont
-- presque tous encore en hyprlang.
--
-- Porté depuis dotfiles/sway/.config/sway/config le 2026-09-04. L'inventaire de
-- ce qui n'a pas d'équivalent est en bas de fichier.


-- ─── Variables ──────────────────────────────────────────────────────────────

local mod  = "SUPER"
local term = "foot"

-- hjkl pour le focus, comme sous Sway. Écart assumé au défaut : les flèches
-- nues déplacent la FENÊTRE, pas le focus — déplacer une fenêtre est plus
-- fréquent que déplacer le focus.
local left, down, up, right = "H", "J", "K", "L"


-- ─── Clavier ────────────────────────────────────────────────────────────────
--
-- Même piège que sous Sway, et il vaut pour tout compositeur Wayland :
-- /etc/X11/xorg.conf.d/00-keyboard.conf n'est lu que par Xorg, et gsettings
-- que par GNOME. Sans ce bloc, retour au défaut US QWERTY.
--
-- Vérifier ce que voit Hyprland :  hyprctl devices

hl.config({
    input = {
        kb_layout    = "fr",
        kb_variant   = "azerty",
        follow_mouse = 1,
        sensitivity  = 0,
    },
})


-- ─── Écrans ─────────────────────────────────────────────────────────────────
--
--   HDMI-A-2            DP-3              DP-1
--   P2425H              P2725DE           P2414H
--   1920x1080           2560x1440         1920x1080
--   ┌────────┐      ┌──────────────┐      ┌────────┐
--   │ gauche │      │    centre    │      │ droite │
--   └────────┘      └──────────────┘      └────────┘
--   x=0             x=1920                x=4480
--
-- Le y=180 des deux latéraux n'est pas arbitraire : ils font 1080 de haut
-- contre 1440 pour le central. (1440-1080)/2 = 180 les centre verticalement au
-- lieu de les aligner par le haut — la souris traverse alors sans décrochage.
--
-- « preferred » plutôt qu'un mode écrit en dur : le taux de rafraîchissement
-- réel des dalles n'a pas été relevé, et une valeur inventée ferait échouer la
-- sortie en silence. À figer après « hyprctl monitors » si besoin.
--
-- Nommage par PORT, choix assumé : le branchement ne bouge pas.

hl.monitor({ output = "HDMI-A-2", mode = "preferred", position = "0x180",   scale = 1 })
hl.monitor({ output = "DP-3",     mode = "preferred", position = "1920x0",  scale = 1 })
hl.monitor({ output = "DP-1",     mode = "preferred", position = "4480x180", scale = 1 })

-- Toute sortie non listée est activée à sa position préférée plutôt qu'ignorée.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })


-- ─── Répartition des espaces de travail ─────────────────────────────────────
--
--     gauche      centre      droite
--     1 4 7 10    2 5 8       3 6 9
--
-- La rangée du clavier reproduit la disposition physique du bureau : première
-- touche à gauche, deuxième au centre, troisième à droite, puis on recommence.
-- Rien à mémoriser, la main sait où elle va.
--
-- L'espace 2 est « default », donc la session démarre au CENTRE et non à
-- gauche. C'est ce qui tient lieu d'« écran principal », notion qui n'existe
-- pas sous Wayland.

local ecran_de_lespace = {
    "HDMI-A-2", "DP-3", "DP-1",
    "HDMI-A-2", "DP-3", "DP-1",
    "HDMI-A-2", "DP-3", "DP-1",
    "HDMI-A-2",
}

for i, sortie in ipairs(ecran_de_lespace) do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor   = sortie,
        default   = (i == 2) or nil,
    })
end


-- ─── Apparence ──────────────────────────────────────────────────────────────
--
-- C'EST LA RAISON DU CHANGEMENT DE COMPOSITEUR. Animations, coins arrondis,
-- flou et ombres n'ont aucun équivalent sous Sway : wlroots ne les fournit pas,
-- par choix amont. La chrome de Sway était déjà réduite au minimum (bordure de
-- 2 px, aucune barre de titre), donc le manque n'était pas un défaut de
-- configuration.
--
-- Bordure conservée à 2 px : en tuilage sur trois écrans, la couleur du focus
-- reste nécessaire pour savoir où va le clavier.

hl.config({
    general = {
        border_size = 2,
        gaps_in     = 4,
        gaps_out    = 8,
        layout      = "dwindle",

        resize_on_border = true,

        col = {
            active_border   = "rgba(88c0d0ee)",
            inactive_border = "rgba(3b4252aa)",
        },
    },

    decoration = {
        rounding       = 8,
        rounding_power = 2,

        -- Le flou ne s'applique qu'aux surfaces TRANSPARENTES : sans opacité
        -- < 1 quelque part, il ne se verra nulle part. Ce n'est pas un réglage
        -- cassé, c'est ainsi qu'il fonctionne.
        blur = {
            enabled = true,
            size    = 6,
            passes  = 2,
        },

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
        },
    },

    animations = { enabled = true },

    dwindle = {
        preserve_split = true,

        -- Pas de « pseudotile » ici : l'option globale dwindle:pseudotile
        -- N'EXISTE PLUS en 0.56 (hyprctl getoption → « no such option »), alors
        -- que tous les tutoriels la donnent. Le pseudo-tuilage n'est plus qu'une
        -- action par fenêtre — liée plus bas sur $mod+P, comme dans l'exemple
        -- livré par le paquet.
    },

    misc = {
        -- Pas de fond d'écran Hyprland : le fond appartient à Noctalia.
        -- Même raisonnement que la directive « bg » abandonnée sous Sway —
        -- deux composants sur la même couche, c'est l'ordre de CRÉATION qui
        -- décide, donc on supprime le concurrent plutôt que de gagner la course.
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})

hl.curve("doux", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 4.5, bezier = "doux", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.0, bezier = "doux", style = "popin 85%" })
hl.animation({ leaf = "border",     enabled = true, speed = 6.0, bezier = "doux" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3.5, bezier = "doux" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.0, bezier = "doux", style = "slide" })

hl.env("XCURSOR_SIZE",   "24")
hl.env("HYPRCURSOR_SIZE", "24")


-- ─── Placement des applications ─────────────────────────────────────────────
--
-- On désigne un ESPACE, jamais une sortie. L'espace 6 vit déjà sur DP-1, donc
-- l'écran de droite : « bureau 6 » et « écran de droite » nomment le même
-- endroit, et une seule affectation fait foi. Si un écran change de prise, il
-- n'y a que le bloc « monitor » à corriger.
--
-- Espace 6 et non 3 : 3 est le premier espace généraliste de DP-1, la VM le
-- partagerait. 6 lui est dédié, et reste atteignable au clavier.
--
-- Sous Sway il fallait DEUX directives — « assign » pour placer, « for_window
-- focus » pour y aller.
--
-- Le critère « class » correspond à l'app_id d'un client Wayland natif, ce
-- qu'est virt-manager. Ne pas deviner : le lire sur une fenêtre réellement
-- ouverte, avec « hyprctl clients ».

hl.window_rule({
    name      = "vm-admin-sur-espace-6",
    match     = { class = "^(virt-manager)$" },
    workspace = "6",
})


-- ═══ TUILAGE ════════════════════════════════════════════════════════════════

-- --- Lancer, fermer, recharger ---

hl.bind(mod .. " + Return",    hl.dsp.exec_cmd(term))
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))

-- Souris + Super : glisser une fenêtre, clic droit pour redimensionner.
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- --- Déplacer le focus et les fenêtres ---

hl.bind(mod .. " + " .. left,  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + " .. down,  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + " .. up,    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + " .. right, hl.dsp.focus({ direction = "right" }))

hl.bind(mod .. " + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + right", hl.dsp.window.move({ direction = "right" }))

hl.bind(mod .. " + SHIFT + " .. left,  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + " .. down,  hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + " .. up,    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + " .. right, hl.dsp.window.move({ direction = "right" }))


-- --- Cycler entre les fenêtres d'un même espace ---
--
-- PIÈGE REPRIS DE SWAY, et il vaut à l'identique ici. Maj+Tab ne produit pas le
-- symbole « Tab » mais « ISO_Left_Tab » : une liaison écrite « SUPER + SHIFT +
-- Tab » ne se déclencherait jamais. D'où le code physique — Tab = 23.

hl.bind(mod .. " + Tab",                    hl.dsp.window.cycle_next())
hl.bind(mod .. " + SHIFT + ISO_Left_Tab",   hl.dsp.window.cycle_next({ prev = true }))


-- --- Espaces de travail : par CODE, et surtout pas par symbole ---
--
-- LE PIÈGE AZERTY LE PLUS COÛTEUX DE L'ANCIENNE CONFIG, et il n'a rien de
-- spécifique à Sway : il vient du CLAVIER, donc il se repose ici entier.
--
-- Sur AZERTY, le symbole « 1 » est au NIVEAU 2 de la touche : elle donne « & »
-- seule et « 1 » avec Maj. Une liaison « SUPER + 1 » exige donc déjà un Maj, et
-- « SUPER + SHIFT + 1 » en demanderait un second — inatteignable.
--
-- VÉRIFIÉ le 2026-09-04 sur la documentation Hyprland : « input:resolve_binds_
-- by_sym » vaut TRUE par défaut, donc les liaisons se résolvent bien par
-- SYMBOLE et le piège s'applique. Il ne suffit pas de changer de compositeur.
--
-- Seule réponse correcte : « code:N », le code de la touche PHYSIQUE, sans
-- passer par un symbole ni par un niveau. Codes lus dans
-- /usr/share/X11/xkb/keycodes/evdev — rangée du haut de gauche à droite :
-- AE01=10, AE02=11 … AE10=19. Sur ce clavier ce sont & é " ' ( - è _ ç à.
--
-- Un symbole, un code de touche et un niveau sont trois choses distinctes.

-- Niveau 1 de la rangée du haut, de gauche à droite : ce que la touche produit
-- SANS Maj. C'est par ces symboles qu'on atteint la touche sans exiger de Maj.
-- Niveau 2 = le chiffre lui-même, donc « SHIFT + le chiffre » désigne la MÊME
-- touche physique. Les deux colonnes ci-dessous sont donc la même touche, lue
-- à ses deux niveaux — et c'est exactement ce qu'on veut.
local rangee = {
    { niveau1 = "ampersand",  niveau2 = "1"  },  -- &  AE01
    { niveau1 = "eacute",     niveau2 = "2"  },  -- é  AE02
    { niveau1 = "quotedbl",   niveau2 = "3"  },  -- "  AE03
    { niveau1 = "apostrophe", niveau2 = "4"  },  -- '  AE04
    { niveau1 = "parenleft",  niveau2 = "5"  },  -- (  AE05
    { niveau1 = "minus",      niveau2 = "6"  },  -- -  AE06
    { niveau1 = "egrave",     niveau2 = "7"  },  -- è  AE07
    { niveau1 = "underscore", niveau2 = "8"  },  -- _  AE08
    { niveau1 = "ccedilla",   niveau2 = "9"  },  -- ç  AE09
    { niveau1 = "agrave",     niveau2 = "0"  },  -- à  AE10
}

for i, touche in ipairs(rangee) do
    hl.bind(mod .. " + " .. touche.niveau1,
            hl.dsp.focus({ workspace = i }),
            { desc = "Aller sur l'espace " .. i })
    hl.bind(mod .. " + SHIFT + " .. touche.niveau2,
            hl.dsp.window.move({ workspace = i }),
            { desc = "Envoyer la fenêtre sur l'espace " .. i })
end


-- --- Dispositions ---
--
-- « dwindle » n'a pas de splith/splitv séparés : une seule bascule
-- d'orientation, contre deux directives sous Sway. SUPER+V reste donc libre.

hl.bind(mod .. " + B",             hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + F",             hl.dsp.window.fullscreen())
hl.bind(mod .. " + P",             hl.dsp.window.pseudo())
hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))

-- Groupes : l'équivalent le plus proche de la disposition « onglets » de Sway.
hl.bind(mod .. " + W",         hl.dsp.group.toggle())
hl.bind(mod .. " + S",         hl.dsp.group.next())
hl.bind(mod .. " + SHIFT + S", hl.dsp.group.prev())


-- --- Espace spécial (l'ancien scratchpad) ---
--
-- Le défaut de Sway liait le scratchpad à $mod+minus. Sur AZERTY « minus » est
-- le niveau 1 de AE06 — la touche du 6 : deux liaisons se disputaient la même
-- touche physique et l'espace 6 ne répondait plus.
--
-- Réattribué sur « ² » (TLDE, code 49), touche libre et isolée en haut à
-- gauche, hors de la rangée des chiffres. Aucune collision possible.

hl.bind(mod .. " + twosuperior",       hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + ALT + twosuperior", hl.dsp.window.move({ workspace = "special:magic" }))


-- --- Mode redimensionnement ---
--
-- Sway avait un « mode », Hyprland a des « submaps » : les touches changent de
-- sens jusqu'à Entrée ou Échap. « repeating » pour que le maintien répète.

hl.define_submap("resize", function()
    local pas = 20
    local sens = {
        [left] = { -pas, 0 }, [down] = { 0, pas },
        [up]   = { 0, -pas }, [right] = { pas, 0 },
        ["left"] = { -pas, 0 }, ["down"] = { 0, pas },
        ["up"]   = { 0, -pas }, ["right"] = { pas, 0 },
    }
    for touche, delta in pairs(sens) do
        hl.bind(touche, hl.dsp.window.resize({ x = delta[1], y = delta[2] }), { repeating = true })
    end
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

hl.bind(mod .. " + R", hl.dsp.submap("resize"))


-- ═══ NOCTALIA — tout le reste ═══════════════════════════════════════════════
--
-- POURQUOI LES RACCOURCIS SONT ICI ET NON DANS NOCTALIA.
-- Noctalia n'a aucun système de raccourcis, et ne peut pas en avoir : sous
-- Wayland, seul le compositeur voit le clavier. Le partage est donc inchangé —
-- le compositeur capte la FRAPPE, Noctalia fournit le COMPORTEMENT et
-- l'AFFICHAGE (l'OSD notamment). Les lignes ci-dessous sont des appels IPC.
--
-- Les commandes :        noctalia msg --help
-- Aide d'une commande :  noctalia msg session --help
--
-- À NOTER : Noctalia 5 est livré en BINAIRE NATIF (/usr/bin/noctalia). Ce
-- n'est plus une configuration Quickshell comme en version 3 — quickshell n'est
-- ni installé ni requis.

hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia --daemon")

    -- Ce que sway-systemd faisait tout seul sous Fedora. Sans ces deux lignes,
    -- les portails xdg-desktop-portal ne savent pas dans quelle session ils
    -- tournent : capture d'écran et sélecteur de fichiers échouent.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
end)

-- Lanceur d'applications.
hl.bind(mod .. " + D", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))

-- Menu de session : lock, suspend, logout, reboot, shutdown.
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))

-- Verrouillage direct.
--
-- PAS Super+L, le réflexe Windows : « L » est le focus droite ici. Ctrl+Alt+L
-- est l'autre convention répandue — GNOME, Xfce et Cinnamon la lient toutes —
-- donc la mémoire musculaire reste valable ailleurs, y compris sur les postes
-- administrés.
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock"))

-- Son et luminosité. Le gain n'est pas la commande mais l'OSD : Noctalia
-- affiche le niveau, ce que pactl ne faisait pas. « locked » : actif écran
-- verrouillé.
local osd = { locked = true, repeating = true }
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("noctalia msg volume-mute"),     { locked = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("noctalia msg volume-down"),     osd)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("noctalia msg volume-up"),       osd)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("noctalia msg mic-mute"),        { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), osd)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),   osd)

-- Capture d'écran.
hl.bind("Print",            hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind("SHIFT + Print",    hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("CTRL + ALT + P",   hl.dsp.exec_cmd("noctalia msg screenshot-region"))


-- ═══ CE QUI N'A PAS D'ÉQUIVALENT — inventaire honnête ═══════════════════════
--
-- Reprendre une config de tuilage d'un compositeur à l'autre n'est pas une
-- traduction ligne à ligne. Ce qui a été perdu, pour ne pas le chercher en vain :
--
--   Sway                          Hyprland
--   ────────────────────────────  ─────────────────────────────────────────────
--   splith / splitv (deux sens)   togglesplit — une seule bascule
--   layout tabbed                 groupes, approchant mais pas identique
--   layout stacking               AUCUN équivalent
--   focus mode_toggle             AUCUN équivalent
--   focus parent                  AUCUN équivalent en dwindle
--   include /etc/sway/config.d/*  AUCUN équivalent — d'où le bloc hyprland.start
--
-- CE QUI MANQUE ENCORE, volontairement laissé de côté : il n'y a pas de
-- « hyprland-session.target » lié à graphical-session.target. Or
-- nas-infoadmin.service est en After=/PartOf=/WantedBy=graphical-session.target :
-- le montage NAS ne partira donc PAS tout seul au login. À traiter avec le
-- greeter. Ne pas « démarrer graphical-session.target » à la main : c'est une
-- cible passive, ce n'est pas ainsi qu'elle s'utilise.
--
-- À TESTER, PAS À SUPPOSER :
--   hyprctl devices   -> la disposition fr/azerty est bien active
--   hyprctl monitors  -> les trois écrans sont aux bonnes positions
--   hyprctl binds     -> les liaisons sont enregistrées, y compris les code:NN
