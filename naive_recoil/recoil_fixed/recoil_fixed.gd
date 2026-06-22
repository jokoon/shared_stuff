extends Node2D

@onready var impact_templ2 = preload("res://bul_impact_2d.tscn")
@onready var crosshair_origin: Vector2 = $center.position
var impact_lifespan: float = .5
'''
trying a new approach

separating aimview punch and impacts
impacts are still done in sequence, with a pattern timer
instead, aimview punch N is just the vector between impacts N and N+1, multiplied by 2


try this:

make impact points x2

punch directly one by one, but with teleporting to each icon
just decay normally to 0

should be able to use an integer pattern_index instead, as long as the trigger is pulled
increasing that index is linear

BUT decreasing it is not:
    it's linear around bullet 1-10
    and then exponential after

'''

func create_impact(pt: Vector2):
    var impact: Sprite2D = impact_templ2.instantiate()
    impact.position = pt
    $impacts.add_child(impact)
    impact.modulate = Color.from_hsv(randf(), 1., 1.)
    var _tween = impact.create_tween()
    _tween.tween_property(impact, "modulate:a", .0, impact_lifespan)
    _tween.tween_callback(impact.queue_free)
func check_errors(text: String):
    var json = JSON.new()
    var error = json.parse(text)
    if error != OK:
        print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
func load_json():
    var file = FileAccess.open("res://patterns_cs2.nogit.json",
        FileAccess.READ)
    if file == null:
        print('res://patterns_cs.nogit.json NOT FOUND')
        return
    var text = file.get_as_text()
    var finished = JSON.parse_string(text)
    if finished == null:
        check_errors(text)
        print('NOT PARSED')
    var results = {}
    for entry in finished:
        var wp_name: String = entry[0]
        var kicks: PackedVector2Array
        for val in entry[1]:
            kicks.append(Vector2(val[0], val[1]))
        var delay: float = float(entry[2])/1000.
        results[wp_name] = [kicks, delay]
    return results


# measure time between shots
var timer_float: float = 0.

# player input for the trigger being pulled
var trigger_pulled: bool= false

#data for each weapon
var kick_per_wp: Dictionary[String, PackedVector2Array]
var delays: Dictionary[String, float]

# delay between each shot
var delay_current: float
# how much the weapon kicks for each shot index
var kicks_current: PackedVector2Array
# the array above, but summed for each index: [0], [0]+[1], [0]+[1]+[2], etc
var impacts_current: PackedVector2Array

# the orientation of the crosshair, meaning where the player points at, at the screen center
var angle_view: Vector2

# how fast if angleview decaying when trigger is released
var decay_rate: float = 100
# the current impact
var impact_index: int = 0
# the the maximum angleview
var angleview_max: float
func calc_pattern_impacts(kicks: PackedVector2Array):
    var current_impact: Vector2 = Vector2.ZERO
    var impacts: PackedVector2Array
    for a in kicks:
        impacts.append(current_impact)
        current_impact+=a
    print(impacts)
    return impacts

func reset():
    # setting up data
    delay_current = delays['ak47']
    kicks_current = kick_per_wp['ak47']
    impacts_current = calc_pattern_impacts(kicks_current)
    angle_view = Vector2(0,0)
    timer_float = 0.

    var angleview_lengths = []
    for a in impacts_current:
        angleview_lengths.append(a.length())
    # finding the max angleview
    # since aimview is half, we half it here too
    angleview_max = angleview_lengths.max()*.5
func _process(delta: float) -> void:
    # we differentiate between trigger pulled and released
    if trigger_pulled:
        if timer_float <= 0.:
            # record an impact shot
            create_impact(impacts_current[impact_index]+crosshair_origin)
            # increment impact index with a min() call
            impact_index =min(impact_index+1, impacts_current.size()-1)
            # the crosshair aims half of the height of the actual impact
            angle_view = impacts_current[impact_index]*.5
            # increasing the timer, weapons have different fire rates
            timer_float += delay_current
        else:
            # decreasing the timer
            timer_float -= delta

    else:
        var angleview_ratio: float = angle_view.length()/angleview_max
        impact_index = int(impacts_current.size()*ease(angleview_ratio, 2.))
    angle_view = angle_view.move_toward(Vector2.ZERO, delta*decay_rate)

    ($crosshair as Sprite2D).position = angle_view+crosshair_origin

    $diagnose.diag['angle_view'] = angle_view
    $diagnose.diag['timer_float'] = timer_float
    $diagnose.diag['angle_view.length()'] = int(angle_view.length())
    $diagnose.diag['impact_index'] = impact_index
    queue_redraw()
func _draw() -> void:
    var measure = float(impact_index)/float(impacts_current.size())
    var rect_size = Rect2(300., 400.-measure*100., 20, measure*100.)
    $diagnose.diag['measure'] = measure
    $diagnose.diag['rect_size'] = rect_size
    draw_rect(rect_size, Color.WHITE, true)

    #draw_circle(impacts_current[impact_index]*.5+crosshair_origin,30, Color.WHITE, false, 1.0)
    draw_circle(impacts_current[impact_index]+crosshair_origin,30, Color.WHITE, false, 1.0)

func _input(event):
    if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
        trigger_pulled = event.is_pressed()
    if (event is InputEventKey and event.keycode == KEY_SPACE):
        reset()
func _ready():
    var results = load_json()
    for weap in results:
        kick_per_wp[weap] = results[weap][0]
        delays[weap] = results[weap][1]
    reset()

    #kicks_current = kick_per_wp['mp5sd']
    #delay_current = delays['mp5sd']
