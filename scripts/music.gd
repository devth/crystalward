extends Node
## Background music — dark fantasy synthwave loops (pads, bass pump, arps).
## Autoloaded as Music. Falls back to a procedural synthwave bed if Ogg missing.

enum Track { TITLE, MAP_SELECT, BATTLE, VICTORY, SILENCE }

var _player: AudioStreamPlayer
var _current: Track = Track.SILENCE
var _use_proc: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = &"Master"
	_player.volume_db = -14.0
	add_child(_player)


func play(track: Track) -> void:
	if track == _current and (_player.playing or _use_proc):
		return
	_current = track
	_use_proc = false
	_player.stop()
	var path := _path_for(track)
	if path != "" and (FileAccess.file_exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path))):
		var stream: AudioStream = load(path) as AudioStream
		if stream:
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			elif stream is AudioStreamMP3:
				(stream as AudioStreamMP3).loop = true
			elif stream is AudioStreamWAV:
				(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			_player.stream = stream
			_player.volume_db = -13.0
			_player.play()
			return
	_use_proc = true
	_start_proc_bed(track)


func stop() -> void:
	_current = Track.SILENCE
	_use_proc = false
	_player.stop()


func _path_for(track: Track) -> String:
	match track:
		Track.TITLE:
			return "res://assets/third_party/music/title.ogg"
		Track.MAP_SELECT:
			return "res://assets/third_party/music/map_select.ogg"
		Track.BATTLE:
			return "res://assets/third_party/music/battle.ogg"
		Track.VICTORY:
			return "res://assets/third_party/music/victory.ogg"
		_:
			return ""


func _start_proc_bed(track: Track) -> void:
	# Dark fantasy synthwave fallback — phrygian/dorian, bass pump, arps
	var root := 55.0
	var intervals: Array = [1.0, 1.5, 2.0, 2.4, 3.0]
	var vol := -20.0
	var duration := 7.0
	var tense := false
	var arp_bright := false
	var bpm := 90.0
	match track:
		Track.TITLE:
			root = 55.0
			intervals = [1.0, 1.189, 1.5, 2.0, 2.378, 3.0, 4.0]
			vol = -19.0
			duration = 8.5
			bpm = 86.0
		Track.MAP_SELECT:
			root = 65.4
			intervals = [1.0, 1.333, 1.5, 1.8, 2.0, 2.667, 3.0]
			vol = -20.0
			duration = 7.5
			arp_bright = true
			bpm = 92.0
		Track.BATTLE:
			root = 49.0
			intervals = [1.0, 1.189, 1.5, 1.782, 2.0, 2.5, 3.0]
			vol = -17.0
			duration = 8.0
			tense = true
			bpm = 98.0
		Track.VICTORY:
			root = 73.4
			intervals = [1.0, 1.25, 1.5, 1.778, 2.0, 2.5, 3.0, 4.0]
			vol = -19.0
			duration = 7.0
			arp_bright = true
			bpm = 100.0
		_:
			return
	_play_proc_pad(root, intervals, duration, vol, tense, arp_bright, bpm)


func _play_proc_pad(root: float, intervals: Array, duration: float, vol: float, tense: bool, arp_bright: bool, bpm: float = 90.0) -> void:
	var sample_rate := 22050
	var frames := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var n_int := intervals.size()
	var beat := 60.0 / maxf(60.0, bpm)
	var arp_steps: Array = [0, 2, 4, 2, 0, 4, 5, 4]
	var arp_hz_step := beat / 4.0 if tense else beat / 2.5
	var bass_steps: Array = [0, 0, 2, 0, 1, 0, 4, 0]
	var bass_step := beat * 0.5
	for i in frames:
		var t := float(i) / float(sample_rate)
		var edge := float(i) / float(maxi(1, frames - 1))
		var env := 1.0
		if edge < 0.08:
			env = edge / 0.08
		elif edge > 0.88:
			env = (1.0 - edge) / 0.12
		env = clampf(env, 0.0, 1.0)
		# Sidechain pump on the beat
		var beat_ph := fmod(t / beat, 1.0)
		var pump := 0.62 + 0.38 * (1.0 - exp(-beat_ph * 8.0)) * exp(-beat_ph * 3.2)
		var flutter := 1.0 + 0.0015 * sin(TAU * 0.35 * t)
		var bright := 0.40 + 0.30 * (0.5 + 0.5 * sin(TAU * 0.025 * t))
		if tense:
			bright = 0.48 + 0.28 * (0.5 + 0.5 * sin(TAU * 0.04 * t))
		var s := 0.0
		# Detuned supersaw pad
		for k in n_int:
			var mult: float = float(intervals[k])
			var amp := 0.075 * pow(0.84, float(k))
			var f0 := root * mult * flutter
			var det := 0.4 + 0.1 * float(k)
			var harm := 2 + int(5.0 * bright)
			var tone := 0.0
			for h in harm:
				var hk := h + 1
				var ha := (1.0 / float(hk)) * pow(bright, float(hk) * 0.38)
				tone += sin(TAU * f0 * float(hk) * t) * ha
				tone += sin(TAU * (f0 + det) * float(hk) * t) * ha * 0.85
			s += tone * amp * 0.36
		# Sequenced bass + sub
		var bi := int(t / bass_step) % bass_steps.size()
		var bidx: int = mini(int(bass_steps[bi]), n_int - 1)
		var bf := root * float(intervals[bidx]) * flutter
		var blocal := t - float(int(t / bass_step)) * bass_step
		var benv := 1.0
		if blocal < 0.012:
			benv = blocal / 0.012
		elif blocal > bass_step * 0.7:
			benv = maxf(0.0, 1.0 - (blocal - bass_step * 0.7) / (bass_step * 0.3))
		var bass := sin(TAU * bf * t) * 0.12 + sin(TAU * bf * 0.5 * t) * 0.09
		bass += sin(TAU * bf * 2.0 * t) * 0.04
		s += bass * benv * pump
		# Synthwave arp plucks
		var step_i := int(t / arp_hz_step)
		var step_t := t - float(step_i) * arp_hz_step
		if step_t < arp_hz_step * 0.9:
			var idx: int = int(arp_steps[step_i % arp_steps.size()])
			idx = mini(idx, n_int - 1)
			var amult: float = float(intervals[idx])
			var af := root * amult * (2.0 if arp_bright else 1.0) * flutter
			var ae := exp(-step_t * 8.0) * (1.0 - exp(-step_t * 50.0))
			var pluck := sin(TAU * af * t) * 0.5 + sin(TAU * af * 2.0 * t) * 0.22
			s += pluck * ae * 0.13 * (0.85 + 0.15 * pump)
		# Haunting lead
		var motif_phase := fmod(t * 0.16, 1.0)
		if motif_phase < 0.28:
			var me := sin(PI * motif_phase / 0.28) * exp(-motif_phase * 1.6)
			var mf := root * 2.0 * flutter * (1.0 + 0.004 * sin(TAU * 5.2 * t))
			s += (sin(TAU * mf * t) * 0.55 + sin(TAU * mf * 3.0 * t) * 0.08) * me * 0.11
		# Crystal FM ping
		var ping := fmod(t * 0.19, 1.0)
		if ping < 0.08:
			var pe := exp(-ping * 32.0) * (1.0 - exp(-ping * 70.0))
			var pf := root * 6.0
			var fm := 2.0 * exp(-ping * 3.0) * sin(TAU * pf * 3.0 * t)
			s += sin(TAU * pf * t + fm) * pe * 0.05
		s += randf_range(-1.0, 1.0) * 0.009 * (0.5 + 0.5 * sin(TAU * 0.09 * t))
		s *= env * (0.55 + 0.45 * pump)
		var v := int(clampf(s, -1.0, 1.0) * 27000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	wav.data = bytes
	_player.stream = wav
	_player.volume_db = vol
	_player.play()


func _process(_delta: float) -> void:
	if _use_proc and not _player.playing and _current != Track.SILENCE:
		_start_proc_bed(_current)
