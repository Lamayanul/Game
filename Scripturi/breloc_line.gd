extends Line2D

# Configurare
@export var length: int = 15       # Lungimea firului (număr de segmente)
@export var constraint: float = 5.0 # Distanța dintre puncte
@export var gravity: Vector2 = Vector2(0, 500) # Gravitația
@export var damp: float = 0.9      # Rezistența la aer (amortizare)
@export var stiffness: int = 10    # Cât de rigid e firul (mai mare = mai rigid)

@onready var charm_sprite = $"../charm_sprite" # Referința la imaginea de jos

var pos: Array = []
var pos_prev: Array = []

func _ready():
	# Inițializăm punctele firului
	for i in range(length):
		pos.append(global_position + Vector2(0, i * constraint))
		pos_prev.append(global_position + Vector2(0, i * constraint))
	
	# Setăm textura line2D să fie mai subțire sau cum dorești
	width = 2.0

func _physics_process(delta):
	update_points(delta)
	update_constrain()
	update_visuals()

func update_points(delta):
	for i in range(length):
		# Dacă e primul punct, îl fixăm de părinte (mâna jucătorului/UI)
		if i == 0:
			pos[i] = global_position
			pos_prev[i] = global_position # Resetăm viteza primului punct
			continue
		
		# Calculăm viteza bazată pe poziția anterioară (Verlet Integration)
		var velocity = (pos[i] - pos_prev[i]) * damp
		pos_prev[i] = pos[i]
		
		# Aplicăm gravitația și viteza
		pos[i] += velocity + (gravity * delta * delta)

func update_constrain():
	# Facem firul să stea unit (distanță fixă între puncte)
	for k in range(stiffness):
		for i in range(length - 1):
			var dist = pos[i].distance_to(pos[i+1])
			var diff = dist - constraint
			if dist == 0: dist = 0.1 # Evităm împărțirea la 0
			var correction = (pos[i] - pos[i+1]) / dist * (diff * 0.5)
			
			# Primul punct e ancorat, nu îl mutăm decât pe al doilea
			if i == 0:
				pos[i+1] += correction * 2 # Tot corecția se duce în jos
			else:
				pos[i] -= correction
				pos[i+1] += correction

func update_visuals():
	# Desenăm firul
	clear_points()
	for p in pos:
		add_point(to_local(p))
	
	# Mutăm și rotim imaginea brelocului la ultimul punct
	if charm_sprite:
		var end_pos = pos[length-1]
		var prev_pos = pos[length-2]
		
		charm_sprite.global_position = end_pos
		
		# Calculăm rotația pentru a atârna natural
		var direction = (end_pos - prev_pos).normalized()
		charm_sprite.rotation = direction.angle() - PI/2 # Ajustează -PI/2 în funcție de sprite-ul tău
