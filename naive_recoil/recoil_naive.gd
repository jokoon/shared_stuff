@tool
extends Node2D

@onready var impact_templ2 = preload("res://bul_impact_2d.tscn")

@onready var crosshair_origin: Vector2 = $center.position

var impact_lifespan: float = .5

# fire mechs
var until_fire: float
var just_shot: bool = false
var fire_period: float
var decocked = false
var trigger_pulled: bool = false
var ammo_clip: int
var automatic = true


# recoil mechs
var recoil_lin: float
var recoil: float


func create_impact(pt: Vector2):
    var impact: Sprite2D = impact_templ2.instantiate()
    impact.position = pt
    $impacts.add_child(impact)
    impact.modulate = Color.from_hsv(randf(), 1., 1.)
    var _tween = impact.create_tween()
    _tween.tween_property(impact, "modulate:a", .0, impact_lifespan)
    _tween.tween_callback(impact.queue_free)
@export_range(0, 1, 0.001) var punch: float = 0.3:
    set(val):
        punch = val
@export_range(1, 10, 0.001) var cool_factor: float = 6.:
    set(val):
        cool = val

        #cool_factor = val
        cool = punch * cool_factor
@export_range(9, 16, 0.1) var fire_hertz: float = 14:
    set(val):
        fire_hertz = val
        fire_period = 1./fire_hertz
var cool = punch * cool_factor

# godot funcs
func upd(delta: float):
    # using naive recoil for now
    recoil_lin = move_toward(recoil_lin, 0., cool*delta)
    if until_fire > 0:
        until_fire -= delta
    else:
        until_fire = 0
    if decocked and not trigger_pulled:
        decocked = false
    if trigger_pulled and until_fire <= 0.:
        if ammo_clip == 0:
            return
        if decocked and automatic == false:
            return
        decocked = true
        just_shot = true
        until_fire = fire_period

        recoil_lin = min(1., punch + recoil_lin)

        # ammunition
        ammo_clip -= 1
func _process(dt:float):
    upd(dt)

    #($diagnose as diagnoser).diag["rec_h"] = recoil_pt.rec_h

    var recoil_scale_centered: float = 25.
    ($crosshair as Sprite2D).position = crosshair_origin + 50*Vector2(0.,-recoil_lin)

    # recoil feedback (cross getting wider with shots)
    ($feedbacked/center2 as Sprite2D).position.x = recoil_lin*(-recoil_scale_centered)
    ($feedbacked/center3 as Sprite2D).position.y = recoil_lin*(-recoil_scale_centered)
    ($feedbacked/center4 as Sprite2D).position.x = recoil_lin*(recoil_scale_centered)
    ($feedbacked/center5 as Sprite2D).position.y = recoil_lin*(recoil_scale_centered)

    #($ammo_bar as ammo_bar).set_ammo(30-0)
    if true:
        $diagnose.diag['recoil_lin'] = "%4.03f" % recoil_lin
        $diagnose.diag['trigger_pulled'] = trigger_pulled
        $diagnose.diag['ammo_clip'] = ammo_clip
func _input(event):
    if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
        trigger_pulled = event.is_pressed()
        $ColorRect.color = Color.RED
    else:
        $ColorRect.color = Color.WHITE
    if (event is InputEventKey
        and event.is_pressed()):
        match event.keycode:
            KEY_ESCAPE: get_tree().quit()
func _ready():
    fire_hertz = 14
    fire_period = 1./fire_hertz
    ammo_clip = 300
    print('cool', cool)
