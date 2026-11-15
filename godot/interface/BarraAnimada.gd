extends ProgressBar
## The real Range value stays authoritative; only its visual fill interpolates.
const ART = preload("res://interface/ArteBarras.gd")
var kind := "blue"
var displayed := 0.0

func _init() -> void:
	step=0

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	show_percentage=false
	step=0
	custom_minimum_size.y=16
	add_theme_stylebox_override("background",StyleBoxEmpty.new())
	add_theme_stylebox_override("fill",StyleBoxEmpty.new())
	displayed=ratio
	value_changed.connect(func(_v):set_process(true))
	set_process(false)

func _process(dt: float) -> void:
	if not is_visible_in_tree():return
	displayed=move_toward(displayed,ratio,dt*4.0)
	queue_redraw()
	if is_equal_approx(displayed,ratio):set_process(false)

func _draw() -> void:
	ART.paint(self,Rect2(Vector2.ZERO,size),displayed,kind)
