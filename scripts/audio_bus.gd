extends Node
## Procedural SFX — ethereal Dark Crystal / soft fantasy.
## Soft sine bells, air whooshes, muted wood — no arcade blips or harsh noise.
## Autoloaded as Sfx.

var _players: Array[AudioStreamPlayer] = []
var _idx: int = 0
const SAMPLE_RATE := 22050


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		p.volume_db = -10.0
		add_child(p)
		_players.append(p)


func _play_pcm(bytes: PackedByteArray, vol: float = -12.0) -> void:
	if _players.is_empty() or bytes.is_empty():
		return
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	var p: AudioStreamPlayer = _players[_idx]
	_idx = (_idx + 1) % _players.size()
	p.stream = wav
	p.volume_db = vol
	p.play()


func _write_sample(bytes: PackedByteArray, i: int, s: float) -> void:
	var sample := int(clampf(s, -1.0, 1.0) * 30000.0)
	if sample < 0:
		sample += 65536
	bytes[i * 2] = sample & 0xFF
	bytes[i * 2 + 1] = (sample >> 8) & 0xFF


func _env_adsr(t: float, dur: float, atk: float = 0.01, rel: float = 0.35) -> float:
	## Soft attack, long release — felt more than heard.
	if dur <= 0.0:
		return 0.0
	var n := t / dur
	if n >= 1.0:
		return 0.0
	var a := atk / maxf(dur, 0.001)
	if n < a:
		return n / maxf(a, 0.0001)
	# Smooth release curve
	var r := (1.0 - n) / maxf(1.0 - a, 0.0001)
	return pow(clampf(r, 0.0, 1.0), rel)


func _soft_noise() -> float:
	## Mild filtered-ish noise (not white hash burst).
	return (randf() + randf() + randf() - 1.5) * 0.45


func _sine(freq: float, t: float, phase: float = 0.0) -> float:
	return sin(TAU * freq * t + phase)


func _tri(freq: float, t: float) -> float:
	var x := fmod(freq * t, 1.0)
	return 1.0 - 4.0 * absf(x - 0.5)


## Soft crystal chime (gather / UI positive).
func gather() -> void:
	var dur := 0.18
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := _env_adsr(t, dur, 0.008, 0.55)
		var s := 0.0
		s += _sine(784.0, t) * 0.28  # G5
		s += _sine(1175.0, t) * 0.14  # D6 partial
		s += _sine(523.0, t) * 0.1
		s *= e
		_write_sample(bytes, i, s)
	_play_pcm(bytes, -16.0)


## Soft stone + crystal settle (build / upgrade).
func build() -> void:
	var dur := 0.22
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e_thump := exp(-t * 28.0)
		var e_chime := _env_adsr(t, dur, 0.02, 0.5)
		var s := 0.0
		# Soft wood/stone body
		s += _sine(95.0, t) * 0.35 * e_thump
		s += _sine(140.0, t) * 0.18 * e_thump
		s += _soft_noise() * 0.06 * e_thump
		# Faint crystal overtone
		s += _sine(660.0, t) * 0.12 * e_chime
		s += _sine(880.0, t) * 0.07 * e_chime
		_write_sample(bytes, i, s)
	_play_pcm(bytes, -14.0)


## Airy ethereal lift — jump / hop (NOT a shot).
func jump() -> void:
	var dur := 0.16
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := _env_adsr(t, dur, 0.005, 0.7)
		# Rising air whoosh (filtered noise + ascending tone)
		var whoosh := _soft_noise() * exp(-t * 14.0) * 0.22
		var lift_f := lerpf(220.0, 480.0, clampf(t / dur, 0.0, 1.0))
		var lift := _sine(lift_f, t) * 0.2 * e
		var air := _sine(lift_f * 1.5, t) * 0.08 * e
		_write_sample(bytes, i, (whoosh + lift + air) * 0.95)
	_play_pcm(bytes, -15.0)


## Soft double-jump / sky hop (slightly brighter).
func jump_double() -> void:
	var dur := 0.14
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := _env_adsr(t, dur, 0.004, 0.65)
		var whoosh := _soft_noise() * exp(-t * 16.0) * 0.18
		var lift_f := lerpf(320.0, 720.0, clampf(t / dur, 0.0, 1.0))
		var lift := _sine(lift_f, t) * 0.18 * e
		var spark := _sine(lift_f * 2.0, t) * 0.06 * e
		_write_sample(bytes, i, whoosh + lift + spark)
	_play_pcm(bytes, -16.0)


## Soft landing thump (muted earth).
func land() -> void:
	var dur := 0.1
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := exp(-t * 40.0)
		var s := _sine(70.0, t) * 0.4 * e
		s += _sine(110.0, t) * 0.15 * e
		s += _soft_noise() * 0.05 * e
		_write_sample(bytes, i, s)
	_play_pcm(bytes, -18.0)


## Warden strike — soft blade / thorn whoosh (not gunshot).
func attack() -> void:
	var dur := 0.12
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := _env_adsr(t, dur, 0.003, 0.85)
		# Air slice
		var slice := _soft_noise() * exp(-t * 22.0) * 0.28
		# Soft mid thorn tone
		var thorn := _tri(190.0 + t * 80.0, t) * 0.16 * e
		var body := _sine(140.0, t) * 0.12 * exp(-t * 25.0)
		_write_sample(bytes, i, slice + thorn + body)
	_play_pcm(bytes, -15.0)


## Soft impact on nightspawn — muted thud + tiny crystal tick.
func hit() -> void:
	var dur := 0.11
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := exp(-t * 32.0)
		var thud := _sine(110.0, t) * 0.32 * e
		thud += _sine(165.0, t) * 0.12 * e
		thud += _soft_noise() * 0.08 * e
		# Tiny ethereal tick
		var tick := _sine(990.0, t) * 0.06 * exp(-t * 50.0)
		_write_sample(bytes, i, thud + tick)
	_play_pcm(bytes, -14.0)


## Tower arrow / soft projectile release.
func shoot() -> void:
	var dur := 0.1
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := exp(-t * 20.0)
		# Bowstring thrum (soft)
		var thrum := _sine(280.0, t) * 0.2 * e
		thrum += _sine(420.0, t) * 0.08 * e
		# Quiet air
		var air := _soft_noise() * exp(-t * 30.0) * 0.1
		_write_sample(bytes, i, thrum + air)
	_play_pcm(bytes, -17.0)


## Soft magic bolt (arcane towers).
func magic_cast() -> void:
	var dur := 0.16
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := _env_adsr(t, dur, 0.01, 0.45)
		var f := lerpf(400.0, 700.0, t / dur)
		var s := _sine(f, t) * 0.22 * e
		s += _sine(f * 1.5, t) * 0.1 * e
		s += _sine(f * 0.5, t) * 0.08 * e
		s += _soft_noise() * 0.04 * e
		_write_sample(bytes, i, s)
	_play_pcm(bytes, -16.0)


## Lightwell takes a wound — low mourning tone.
func crystal_hurt() -> void:
	var dur := 0.35
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := _env_adsr(t, dur, 0.02, 0.4)
		var s := _sine(98.0, t) * 0.35 * e
		s += _sine(130.0, t) * 0.18 * e
		s += _sine(196.0, t) * 0.1 * e
		s += _soft_noise() * 0.04 * exp(-t * 8.0)
		_write_sample(bytes, i, s)
	_play_pcm(bytes, -12.0)


## Soft horn-like swell for surge start.
func wave_start() -> void:
	var dur := 0.32
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := _env_adsr(t, dur, 0.04, 0.5)
		var s := _sine(196.0, t) * 0.22 * e  # G3
		s += _sine(247.0, t) * 0.14 * e  # B3
		s += _sine(294.0, t) * 0.1 * e
		s += _sine(392.0, t) * 0.06 * e
		_write_sample(bytes, i, s)
	_play_pcm(bytes, -15.0)


## Soft rising victory bells.
func win() -> void:
	var notes := [392.0, 494.0, 587.0, 784.0]
	var offset := 0.0
	for n in notes:
		_play_delayed_chime(n, offset, 0.22)
		offset += 0.09


func _play_delayed_chime(freq: float, delay: float, dur: float) -> void:
	get_tree().create_timer(delay).timeout.connect(func():
		var frames := int(SAMPLE_RATE * dur)
		var bytes := PackedByteArray()
		bytes.resize(frames * 2)
		for i in frames:
			var t := float(i) / float(SAMPLE_RATE)
			var e := _env_adsr(t, dur, 0.01, 0.5)
			var s := _sine(freq, t) * 0.28 * e
			s += _sine(freq * 2.0, t) * 0.08 * e
			_write_sample(bytes, i, s)
		_play_pcm(bytes, -14.0)
	)


## Low falling loss.
func lose() -> void:
	var dur := 0.45
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var e := _env_adsr(t, dur, 0.03, 0.35)
		var f := lerpf(220.0, 90.0, t / dur)
		var s := _sine(f, t) * 0.3 * e
		s += _sine(f * 0.5, t) * 0.15 * e
		_write_sample(bytes, i, s)
	_play_pcm(bytes, -12.0)
