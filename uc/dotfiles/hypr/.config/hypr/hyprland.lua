-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Wayland ne connaît ni « écran 1/2/3 » ni « écran principal » : uniquement des
-- sorties placées par coordonnées dans un plan commun. La position décide de
-- tout, à commencer par le bord par lequel la souris passe.
--
--   HDMI-A-2            DP-3              DP-1
--   P2425H              P2725DE           P2414H
--   1920x1080           2560x1440         1920x1080
--   ┌────────┐      ┌──────────────┐      ┌────────┐
--   │ gauche │      │    centre    │      │ droite │
--   └────────┘      └──────────────┘      └────────┘
--   x=0             x=1920                x=4480
--
-- Le y=180 des deux latéraux n'est pas arbitraire : ils font 1080 de haut contre
-- 1440 pour le central. (1440-1080)/2 = 180 les centre verticalement au lieu de
-- les aligner par le haut — la souris traverse alors sans décrochage.
--
-- Nommage par PORT, choix assumé : le branchement ne bouge pas. Si un câble
-- change de prise, c'est ce bloc qu'il faut corriger. L'identifiant durable
-- serait la description, p.ex. "Dell Inc. DELL P2725DE FVTKM84".
-- Pour relire les noms, modes et positions réels :  hyprctl monitors all

hl.monitor({ output = "HDMI-A-2", mode = "preferred", position = "0x180",    scale = 1 })
hl.monitor({ output = "DP-3",     mode = "preferred", position = "1920x0",   scale = 1 })
hl.monitor({ output = "DP-1",     mode = "preferred", position = "4480x180", scale = 1 })

-- Toute sortie non listée est activée à sa position préférée plutôt qu'ignorée.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"

-- « dolphin » (le défaut de l'exemple) n'est pas installé ; nautilus l'est, et
-- il est déjà la brique qui sait écrire dans le trousseau pour les montages SMB.
local fileManager = "nautilus"

-- « hyprlauncher » (le défaut) n'est pas installé. Le lanceur est un panneau
-- Noctalia, appelé en IPC — d'où une commande et non un binaire.
local menu        = "noctalia msg panel-toggle launcher"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Cette session est lancée par greetd, qui passe par uwsm : l'unité du
-- compositeur est wayland-wm@hyprland.desktop.service, en Type=notify.
-- Vérifier comment on est lancé :  pstree -ps $(pgrep -x Hyprland)

hl.on("hyprland.start", function()
    -- « uwsm finalize » fait DEUX choses, et la seconde est la moins visible :
    --
    --   1. il exporte vers systemd --user les variables WAYLAND_DISPLAY et
    --      DISPLAY, plus celles listées dans UWSM_FINALIZE_VARNAMES — ici
    --      HYPRLAND_INSTANCE_SIGNATURE, HYPRLAND_CMD, HYPRCURSOR_THEME,
    --      HYPRCURSOR_SIZE, XCURSOR_SIZE, XCURSOR_THEME ;
    --   2. il envoie la NOTIFICATION DE DÉMARRAGE de l'unité du compositeur.
    --
    -- C'est le point 2 qui compte le plus : l'unité étant en Type=notify, tant
    -- que la notification n'arrive pas, uwsm attend les variables jusqu'au
    -- timeout, l'unité reste en « activating » et graphical-session.target ne
    -- s'active jamais. Or nas-infoadmin.service en dépend
    -- (After=/PartOf=/WantedBy=) : sans cette ligne, le NAS ne monte pas.
    --
    -- Écrire à la main un « dbus-update-activation-environment » suivi d'un
    -- « systemctl --user import-environment » ferait une partie du point 1
    -- (trois variables sur six), rien du point 2, et serait un écart à la
    -- procédure de l'outil sans qu'aucun fait sur la machine ne le justifie.
    hl.exec_cmd("uwsm finalize")

    -- Shell Wayland complet : barre, lanceur, notifications, fond d'écran, OSD,
    -- verrouillage, menu de session. Vérifié le 2026-09-07 : AUCUN autre
    -- mécanisme ne le lance — ni unité systemd (le paquet ne livre qu'un
    -- .desktop), ni autostart XDG. Sans cette ligne, pas de shell du tout.
    hl.exec_cmd("noctalia --daemon")

    -- 3CX (PWA Chromium), ajouté le 2026-09-11. Lancé ici pour être déjà
    -- enregistré auprès du serveur quand le premier appel arrive : la
    -- téléphonie vit dans la PAGE, une application pas ouverte ne sonne pas.
    -- Il atterrit directement dans l'espace spécial « 3cx » (règle plus bas),
    -- donc invisible tant qu'on n'appelle pas SUPER + A.
    --
    -- « uwsm app » et non la ligne Exec du .desktop : l'application obtient sa
    -- propre unité systemd dans app-graphical.slice, comme tout ce que lance le
    -- lanceur. L'argument est un Desktop Entry ID — forme documentée dans
    -- « uwsm app --help » et testée le 2026-09-11.
    --
    -- ÉCART ASSUMÉ à la fiche « poste/ », qui envisageait l'option « Démarrer
    -- l'application à la connexion » de Chromium. Elle écrit dans
    -- ~/.config/autostart/, que rien ne versionne et qu'uwsm transforme en
    -- app-*@autostart.service FILTRÉE par XDG_CURRENT_DESKTOP. Ici le geste est
    -- dans le dépôt et ne dépend d'aucun filtre.
    hl.exec_cmd("uwsm app -- chrome-ofbadnjniahgolcbglpdccmaofcddiig-Default.desktop")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

-- Ancrage des espaces sur les sorties, par NOM et non par ordre de détection.
-- Sans ces règles, Hyprland distribue les espaces dans l'ordre des monitorID,
-- qui est l'ordre de détection au démarrage et change d'un boot à l'autre :
-- le 2026-09-07, DP-1 (écran de droite) avait l'ID 0 et récupérait l'espace 1.
-- `default` désigne l'espace que la sortie affiche à l'ouverture de session.
-- Attention : une règle de workspace ne s'applique qu'à la CRÉATION de l'espace,
-- un `hyprctl reload` ne déplace donc pas ceux qui sont déjà ouverts.
local sorties = {
    "HDMI-A-2", -- écran de gauche  → espaces 1, 4, 7
    "DP-3",     -- écran central    → espaces 2, 5, 8
    "DP-1",     -- écran de droite  → espaces 3, 6, 9
}

for rang, sortie in ipairs(sorties) do
    for _, n in ipairs({ rang, rang + 3, rang + 6 }) do
        hl.workspace_rule({
            workspace = tostring(n),
            monitor   = sortie,
            default   = (n == rang),
        })
    end
end

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        -- /etc/X11/xorg.conf.d/00-keyboard.conf n'est lu que par Xorg, et
        -- gsettings que par GNOME. Sans ces deux lignes, Hyprland retombe sur
        -- son défaut, US QWERTY.  Vérifier :  hyprctl devices
        kb_layout  = "fr",
        kb_variant = "azerty",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- BASE : les raccourcis par défaut d'Hyprland (/usr/share/hypr/hyprland.lua).
-- Chaque écart au défaut est marqué ÉCART ou AJOUT, avec sa raison.
--
-- Voir la forme réellement enregistrée :  hyprctl binds
--
-- ATTENTION — « hyprctl keyword » ne fonctionne PLUS avec le parseur Lua : il
-- répond « keyword can't work with non-legacy parsers. Use eval. » Pour essayer
-- une liaison à chaud, sans toucher au fichier :
--     hyprctl eval 'hl.bind("SUPER + X", hl.dsp.exec_cmd("true"))'
-- Et pour un dispatcher, la forme des arguments n'est PAS documentée dans
-- /usr/share/hypr/stubs/hl.meta.lua (tout y est typé « fun(...) ») : c'est le
-- message d'erreur qui la donne, en la demandant mal exprès.
--     hyprctl dispatch 'hl.dsp.window.resize("x")'


-- --- Lancer, fermer, quitter ---

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))

-- ÉCART — le défaut met la sortie de session sur SUPER + M, qui quitte SANS
-- confirmation : une frappe malheureuse ferme la session et tout ce qui est
-- ouvert. Deux changements : un modificateur de plus, et le panneau de session
-- Noctalia à la place, qui présente lock / suspend / logout / reboot / shutdown
-- au lieu d'agir tout de suite.
-- Pour un logout sec à la place :  noctalia msg session logout
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))


-- --- Disposition des fenêtres ---

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- AJOUT — les défauts d'Hyprland n'ont AUCUN raccourci de plein écran.
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())


-- --- Focus, déplacement, redimensionnement ---
--
-- Les flèches nues déplacent le FOCUS : c'est le défaut d'Hyprland, gardé.
--
-- AJOUT — les défauts ne savent ni DÉPLACER une fenêtre au clavier, ni la
-- REDIMENSIONNER (uniquement à la souris, SUPER + clic droit). Trois
-- modificateurs sur la même rangée de flèches, ce qui évite d'avoir à retenir
-- trois zones du clavier.
--
-- PIÈGE VÉRIFIÉ le 2026-09-07 — « relative = true » n'est pas optionnel.
-- La signature est { x, y, relative?, window? }, et SANS « relative » les deux
-- nombres sont une taille ABSOLUE : { x = 20, y = 0 } demande une hauteur de
-- zéro et échoue sur « Invalid size ». Le message d'erreur est la seule
-- documentation de cette signature.

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

local pas = 40
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -pas, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x =  pas, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -pas, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y =  pas, relative = true }), { repeating = true })


-- --- Espaces de travail ---
--
-- ÉCART OBLIGÉ, ce n'est pas une préférence. Le défaut d'Hyprland lie
-- « SUPER + 1 » … « SUPER + 0 », et « input:resolve_binds_by_sym » valant TRUE
-- par défaut, ce sont bien des SYMBOLES qui sont liés. Or sur AZERTY le symbole
-- « 1 » est au NIVEAU 2 de la touche : elle donne « & » seule et « 1 » avec Maj.
-- « SUPER + 1 » exigerait donc déjà un Maj, et « SUPER + SHIFT + 1 » un second.
-- Le défaut est inutilisable tel quel sur ce clavier.
--
-- « code:N » N'EST PAS la solution — re-vérifié le 2026-09-07 sur Hyprland
-- 0.56.2. Dans la configuration Lua la liaison est acceptée sans erreur, sans
-- avertissement, et reste INERTE. Ce qui le révèle est la FORME de
-- « hyprctl binds » : une liaison analysée montre une clé courte
-- (« key: ampersand »), une liaison ratée garde la chaîne entière
-- (« key: SUPER + ALT + code:49 »). Compter les liaisons n'aurait rien dit.
--
-- Réponse retenue : lier le SYMBOLE DE NIVEAU 1 dans les DEUX cas, et ne
-- changer que le modificateur. Une seule colonne de symboles, deux modmasks.
--
-- PIÈGE MESURÉ le 2026-09-07, et c'est le plus sournois du fichier.
-- La première version écrivait « SUPER + SHIFT + <chiffre> » pour envoyer la
-- fenêtre, en raisonnant que « SHIFT + le chiffre » désigne la même touche lue
-- à son niveau 2. Ce raisonnement est faux EN PRATIQUE : la liaison ne se
-- déclenche jamais.
--
-- Et « hyprctl binds » ne le dit PAS. Les deux formes y sont analysées
-- proprement, avec une clé courte et le bon modmask :
--     key: 1           modmask: 65   (SUPER + SHIFT)
--     key: ampersand   modmask: 65   (SUPER + SHIFT)
-- Le critère « clé courte = liaison bonne », qui démasque « code:N », ne
-- démasque pas celle-ci. Seule la frappe réelle l'a révélée.
--
-- Explication la plus probable, non vérifiée dans le code d'Hyprland : à la
-- frappe, le keysym comparé est celui du NIVEAU 1 de la touche (« ampersand »),
-- le Maj étant déjà consommé comme modificateur. Aucune touche AZERTY ne
-- produisant « 1 » au niveau 1, la liaison n'a aucune touche à laquelle
-- s'accrocher. Ce qui compte est le constat, pas le mécanisme supposé.

local rangee = {
    "ampersand",   -- & → espace 1
    "eacute",      -- é → espace 2
    "quotedbl",    -- " → espace 3
    "apostrophe",  -- ' → espace 4
    "parenleft",   -- ( → espace 5
    "minus",       -- - → espace 6
    "egrave",      -- è → espace 7
    "underscore",  -- _ → espace 8
    "ccedilla",    -- ç → espace 9
    "agrave",      -- à → espace 10
}

for i, symbole in ipairs(rangee) do
    hl.bind(mainMod .. " + " .. symbole,
            hl.dsp.focus({ workspace = i }),
            { desc = "Aller sur l'espace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. symbole,
            hl.dsp.window.move({ workspace = i }),
            { desc = "Envoyer la fenêtre sur l'espace " .. i })
end

-- Espace spécial (scratchpad) et molette : défauts d'Hyprland, gardés tels quels.
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- --- 3CX : un scratchpad DÉDIÉ, à côté de « magic » (2026-09-11) ---
--
-- POURQUOI UN ESPACE SPÉCIAL ET PAS UNE ICÔNE DANS LA BARRE. Mesuré ce jour :
-- Chromium ne publie qu'UN SEUL StatusNotifierItem pour tout le navigateur
-- (« chrome_status_icon_1 »), dont le menu liste les applications
-- d'arrière-plan — jamais une entrée par PWA. Mattermost, lui, est un Electron
-- qui publie la sienne (« Mattermost_status_icon_1 »), d'où la différence de
-- comportement. Il n'y a donc rien à activer côté 3CX : fermer la fenêtre du
-- PWA ferme 3CX. L'équivalent tuilant de « réduire dans le tray » est l'espace
-- spécial — la fenêtre sort de l'écran, le processus continue de tourner.
--
-- SÉPARÉ de « magic » à dessein : le scratchpad généraliste sert à garer
-- n'importe quoi, et SUPER + S ferait alors apparaître 3CX avec le reste.
--
-- A COMME APPEL — choisi par Julien, et le moyen mnémotechnique compte autant
-- que la disponibilité : « T » avait été retenu pour « téléphone », ça ne lui
-- parlait pas (3CX est sa VOIP). SUPER + A et SUPER + SHIFT + A sont LIBRES,
-- vérifié sur « hyprctl binds » : aucune liaison en modmask 64 ni 65.
--
-- DEUX COMBINAISONS ÉCARTÉES, pour qu'on ne les repropose pas :
--   « SUPER + SHIFT + " » — « quotedbl » est le symbole de NIVEAU 1 de la
--     touche AE03, déjà lié quelques lignes plus haut à « envoyer la fenêtre
--     sur l'espace 3 ». Le conflit est invisible à la lecture du fichier, seul
--     « hyprctl binds » le montre.
--   « SUPER + V » (pour VOIP) — prise deux fois : bascule flottant en
--     modmask 64, historique du presse-papiers Noctalia en modmask 65.
hl.bind(mainMod .. " + A",         hl.dsp.workspace.toggle_special("3cx"),
        { desc = "Afficher / masquer le 3CX" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.window.move({ workspace = "special:3cx" }),
        { desc = "Envoyer la fenêtre dans le scratchpad 3CX" })

-- La fenêtre y va seule à son ouverture. « silent » évite que la session
-- bascule sur l'espace spécial au démarrage.
--
-- LA CLASSE N'EST PAS CELLE DU .desktop. Chromium y écrit
-- « StartupWMClass=crx_<app-id> », mais la classe que voit le compositeur est
-- « chrome-<app-id>-<profil> » — relevée dans « hyprctl clients », pas déduite.
--
-- PIÈGE : une règle de fenêtre ne s'applique qu'à la CRÉATION. « hyprctl
-- reload » ne déplacera pas la fenêtre 3CX déjà ouverte ; il faut la fermer et
-- la rouvrir, ou la pousser à la main par SUPER + SHIFT + A.
hl.window_rule({
    name      = "3cx-scratchpad",
    match     = { class = "^chrome-ofbadnjniahgolcbglpdccmaofcddiig-Default$" },
    workspace = "special:3cx silent",
})

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- --- Shell : tout passe par Noctalia ---
--
-- POURQUOI LES RACCOURCIS SONT ICI ET NON DANS NOCTALIA.
-- Noctalia n'a aucun système de raccourcis, et ne peut pas en avoir : sous
-- Wayland, seul le compositeur voit le clavier. Le partage est donc : le
-- compositeur capte la FRAPPE, Noctalia fournit le COMPORTEMENT et l'AFFICHAGE.
-- Les lignes ci-dessous sont des appels IPC, pas des implémentations.
--
-- Commandes vérifiées le 2026-09-07 sur le binaire natif (Noctalia est en
-- binaire depuis la v5, ce n'est plus une configuration Quickshell) :
--     noctalia msg --help
-- Panneaux : clipboard, control-center, launcher, polkit, session,
--            setup-wizard, test, tray-drawer, wallpaper
-- Actions de session : lock, suspend, lock-and-suspend, logout, reboot, shutdown

-- AJOUT — verrouillage. SUPER + L est LIBRE dans les défauts d'Hyprland (ce
-- sont les flèches qui déplacent le focus, pas hjkl), donc le réflexe Windows
-- est disponible sans rien sacrifier.
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("noctalia msg session lock"))

-- ÉCART — les défauts appellent wpctl et brightnessctl directement. Le gain de
-- Noctalia n'est pas la commande mais l'OSD : le niveau s'affiche à l'écran, ce
-- que les outils bruts ne font pas. « locked » les garde actifs écran verrouillé.
local osd = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("noctalia msg volume-up"),       osd)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("noctalia msg volume-down"),     osd)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("noctalia msg volume-mute"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("noctalia msg mic-mute"),        { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),   osd)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), osd)

-- ÉCART — playerctl est installé, mais passer par Noctalia évite un second
-- chemin de contrôle et donne l'OSD. Actions : next, previous, toggle, play,
-- pause, stop, next-player, previous-player.
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("noctalia msg media next"),     { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("noctalia msg media toggle"),   { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"),   { locked = true })

-- AJOUT — aucune capture d'écran dans les défauts d'Hyprland.
-- « screenshot-fullscreen » prend l'écran focalisé ; il accepte aussi « pick »
-- (choix interactif de l'écran) et « all » (toutes les sorties).
--
-- PAS SUR « Print » — mesuré le 2026-09-08 : sur le Logitech K650 apparié au
-- récepteur Bolt, la touche à l'icône d'imprimante n'émet RIEN au niveau noyau
-- (`libinput debug-events` sur les 15 périphériques : aucun événement). Le bind
-- était donc correct et inatteignable. Voir le journal du poste.
hl.bind(mainMod .. " + SHIFT + P",         hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind(mainMod .. " + CTRL + SHIFT + P",  hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))

-- AJOUT — presse-papiers : Noctalia garde un historique, sans quoi il n'y en a
-- aucun sous Hyprland.
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
