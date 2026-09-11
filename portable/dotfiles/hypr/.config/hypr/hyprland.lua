-- Config Hyprland du portable — reconstruite à partir de uc/dotfiles/hypr, PAS copiée :
-- écran unique interne + externe(s) au besoin (dock), un seul clavier physique, contre
-- trois écrans fixes et 14 périphériques clavier sur uc. Voir README.md pour la décision.


------------------
---- MONITORS ----
------------------

-- Un seul écran mesuré pour l'instant (hyprctl monitors all, 2026-09-11) :
--   eDP-1, LG Display, 1920x1200@60Hz, 340x220mm -> échelle 1.5 pour une densité
--   comparable à un écran de bureau classique.
-- Contrairement à uc (trois écrans fixes, ancrés par port), ce poste est pensé pour être
-- déconnecté/reconnecté à un dock : PAS d'ancrage par workspace pour l'instant, ça se
-- décidera une fois un dock réellement testé (voir README.md, "reste ouvert").

hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.5 })

-- Toute sortie non listée (dock, HDMI externe) est activée à sa position préférée.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })


---------------------
---- MY PROGRAMS ----
---------------------

-- Mêmes choix que uc : kitty (terminal), nautilus (gestionnaire de fichiers, sait écrire
-- dans le trousseau pour les montages SMB), le lanceur Noctalia en IPC.
-- AUCUN DES DEUX PREMIERS N'EST ENCORE INSTALLÉ (étape 8) : SUPER+Q et SUPER+E resteront
-- inertes jusque-là — attendu, pas un bug de cette config.
local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "noctalia msg panel-toggle launcher"


-------------------
---- AUTOSTART ----
-------------------

-- Session lancée par greetd -> uwsm -> Hyprland (comme sur uc). Pas de ligne 3CX ici :
-- Chromium n'est pas installé, aucune décision prise sur ce poste pour l'instant.

hl.on("hyprland.start", function()
    -- Sans ça, l'unité du compositeur (Type=notify) reste "activating" et
    -- graphical-session.target ne s'active jamais — donc pas de montage NAS.
    -- Raison complète : uc/dotfiles/hypr/.config/hypr/hyprland.lua.
    hl.exec_cmd("uwsm finalize")

    -- Shell Wayland complet (barre, lanceur, notifications, fond d'écran, OSD,
    -- verrouillage, menu de session). Aucun autre mécanisme ne le lance.
    hl.exec_cmd("noctalia --daemon")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Identique à uc : aucun de ces réglages ne dépend du matériel.
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
        blur   = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },

    animations = { enabled = true },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
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

hl.config({ dwindle  = { preserve_split = true } })
hl.config({ master   = { new_status = "master" } })
hl.config({ scrolling = { fullscreen_on_one_column = true } })

hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        -- Même disposition que partout ailleurs sur ce projet. Sans ces lignes,
        -- Hyprland retombe sur son défaut US QWERTY (mesuré : hyprctl devices montrait
        -- "English (US)" sur les 8 claviers avant cette config).
        kb_layout  = "fr",
        kb_variant = "azerty",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        -- Pavé tactile RÉEL sur ce poste (absent de uc) : ven_0488:00-0488:108b-touchpad,
        -- mesuré via hyprctl devices. Défaut Hyprland gardé pour tout le reste — aucune
        -- mesure ne justifie un réglage différent pour l'instant.
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Trois doigts, balayage horizontal = changement d'espace. Utile ici pour de vrai,
-- contrairement à uc qui n'a pas de pavé tactile.
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- --- Lancer, fermer, quitter ---

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))

hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))


-- --- Disposition des fenêtres ---

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())


-- --- Focus, déplacement, redimensionnement ---

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
-- Même écart qu'uc, même raison : sur AZERTY le symbole "1".."0" est au NIVEAU 2 de la
-- touche (Maj requis), donc le défaut Hyprland (SUPER + 1..0) est inutilisable. Lier le
-- SYMBOLE DE NIVEAU 1 dans les deux cas, changer seulement le modificateur — PAS
-- "SUPER + SHIFT + <chiffre>", qui ne se déclenche jamais en pratique (mesuré sur uc le
-- 2026-09-07, la cause exacte n'est pas connue mais le constat, si). Détail complet :
-- uc/dotfiles/hypr/.config/hypr/hyprland.lua.

local rangee = {
    "ampersand", "eacute", "quotedbl", "apostrophe", "parenleft",
    "minus", "egrave", "underscore", "ccedilla", "agrave",
}

for i, symbole in ipairs(rangee) do
    hl.bind(mainMod .. " + " .. symbole,
            hl.dsp.focus({ workspace = i }),
            { desc = "Aller sur l'espace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. symbole,
            hl.dsp.window.move({ workspace = i }),
            { desc = "Envoyer la fenêtre sur l'espace " .. i })
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-- --- Shell : tout passe par Noctalia ---
--
-- Noctalia n'a aucun système de raccourcis : sous Wayland, seul le compositeur voit le
-- clavier. Ces lignes sont des appels IPC (noctalia msg --help), pas des implémentations.

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("noctalia msg session lock"))

local osd = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("noctalia msg volume-up"),       osd)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("noctalia msg volume-down"),     osd)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("noctalia msg volume-mute"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("noctalia msg mic-mute"),        { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),   osd)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), osd)

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("noctalia msg media next"),     { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("noctalia msg media toggle"),   { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"),   { locked = true })

hl.bind(mainMod .. " + SHIFT + P",         hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind(mainMod .. " + CTRL + SHIFT + P",  hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))

hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Défauts génériques d'Hyprland, sans dépendance au matériel : gardés tels quels.

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class = "^$", title = "^$", xwayland = true,
        float = true, fullscreen = false, pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})
