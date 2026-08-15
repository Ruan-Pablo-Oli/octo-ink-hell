extends AudioStreamPlayer
class_name MusicManager


@export var track: AudioStream
@export var music_volume_db: float = -6.0


func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS

	stream = track

	volume_db = music_volume_db

	bus = "Music"

	finished.connect(_on_finished)

	if track:
		play()


func _on_finished() -> void:

	play()
