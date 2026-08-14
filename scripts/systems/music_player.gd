extends AudioStreamPlayer
class_name MusicPlayer

@export var track: AudioStream
@export var music_volume_db: float = -6.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  ## continua tocando mesmo com o jogo pausado
	stream = track
	volume_db = music_volume_db
	bus = "Music"
	finished.connect(_on_finished)
	if track:
		play()

func _on_finished() -> void:
	## garante loop independente do formato do audio (ogg/mp3/wav) -
	## nao depende de configuracao de loop no import da faixa.
	play()
