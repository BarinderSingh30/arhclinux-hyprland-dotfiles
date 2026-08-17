-- conf/input.lua -- keyboard, pointer, touchpad, gestures

hl.config({
    input = {
        kb_layout    = "us",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",

        follow_mouse = 1,
        sensitivity  = 0,   -- -1.0 to 1.0; 0 = raw, unaccelerated

        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            tap_to_click         = true,
            drag_lock            = true,
            scroll_factor        = 0.6,  -- default is twitchy on this trackpad
        },
    },
})

-- 3-finger horizontal swipe -> switch workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
