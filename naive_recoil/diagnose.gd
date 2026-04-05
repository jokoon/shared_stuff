#@tool
extends Node2D
class_name diagnoser

var diag: Dictionary = {}
var node_map = {}
var font
var label_setting: LabelSettings
func _init():
    if Engine.is_editor_hint(): return

    #font = FontFile.new()
    #font.font_data = load("res://FiraMono-Regular.ttf")
    label_setting = LabelSettings.new()
    label_setting.outline_size = 5
    label_setting.font_size = 12
    label_setting.outline_color = Color(0, 0, 0, 0.25)
func _process(_dt):
    if Engine.is_editor_hint(): return

    var text: String
    for k in diag:
#        text += str(k)+': '+str(diag[k]) +'\n'
        if k in node_map:
            node_map[k].text = str(k)+': '+str(diag[k])
        else:
            var label = Label.new()
            label.label_settings = label_setting
            label.add_theme_font_override('font', font)
            label.text = str(k)+': '+str(diag[k])
            label.position.y = node_map.size()*label_setting.font_size*1.2
            node_map[k] = label
            $labels.add_child(label)
#    $text.text = text
    for k in node_map:
        if not k in diag:
            (node_map[k] as Label).queue_free()
