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


## Bowstring twang — arrow tower release (pluck + string body + air).
func shoot() -> void:
	arrow_twang()


func arrow_twang() -> void:
	## Real bow feel: sharp string snap, resonant wood body, short arrow whoosh.
	var dur := 0.16
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	# Slight detune per shot so rapid fire isn't a machine gun loop
	var detune := 1.0 + randf_range(-0.03, 0.03)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var s := 0.0

		# Instant string snap (high click of the release)
		var snap_e := exp(-t * 180.0)
		s += _soft_noise() * 0.55 * snap_e
		s += _sine(2400.0 * detune, t) * 0.18 * snap_e

		# Bowstring body — fundamental + fast-decaying harmonics (pluck spectrum)
		var fund := 185.0 * detune
		# Slight pitch drop as string settles
		var pitch_fall := 1.0 - t * 0.12
		var str_e := exp(-t * 14.0)
		s += _sine(fund * pitch_fall, t) * 0.42 * str_e
		s += _sine(fund * 2.01 * pitch_fall, t) * 0.22 * exp(-t * 22.0)
		s += _sine(fund * 3.02 * pitch_fall, t) * 0.12 * exp(-t * 32.0)
		s += _sine(fund * 4.1 * pitch_fall, t) * 0.07 * exp(-t * 45.0)
		s += _tri(fund * 1.5 * pitch_fall, t) * 0.08 * exp(-t * 28.0)

		# Wooden riser / limb thump (very short, low)
		s += _sine(95.0 * detune, t) * 0.2 * exp(-t * 55.0)

		# Arrow air whoosh (band-limited noise, mid only)
		var whoosh := _soft_noise() * 0.22 * exp(-t * 18.0) * smoothstep(0.0, 0.012, t)
		# High shelf for "air" without white-noise hiss
		whoosh += _sine(900.0 + t * 400.0, t) * 0.04 * exp(-t * 25.0)
		s += whoosh

		_write_sample(bytes, i, s * 0.9)
	_play_pcm(bytes, -11.0)


## Magical tinkle-zaps — arcane tower (glass/crystal, not electrical).
func magic_cast() -> void:
	var dur := 0.22
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	# Sparkle pitch set (pentatonic-ish crystal bells)
	var base := 880.0 * (1.0 + randf_range(-0.04, 0.04))
	var notes := [
		base,
		base * 1.25,
		base * 1.5,
		base * 1.875,
		base * 2.25,
	]
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var s := 0.0

		# Soft cast body — warm low-mid swell (spell weight, not buzz)
		var body_e := _env_adsr(t, dur, 0.012, 0.55)
		s += _sine(220.0, t) * 0.1 * body_e
		s += _sine(330.0, t) * 0.06 * body_e

		# Cascading crystal tinkles (staggered onsets)
		for n in notes.size():
			var onset := 0.008 + float(n) * 0.018
			if t < onset:
				continue
			var lt := t - onset
			var ne := exp(-lt * (18.0 + float(n) * 4.0))
			var f: float = notes[n]
			# Gentle downward glide = "zap" without electricity
			var glide := 1.0 - lt * 0.35
			s += _sine(f * glide, t) * 0.22 * ne
			s += _sine(f * glide * 2.01, t) * 0.08 * ne
			# Soft triangle partial for glassy edge (not square/buzz)
			s += _tri(f * glide * 0.5, t) * 0.05 * ne

		# Shimmer dust — very soft high sine grains, no hash crackle
		var shimmer := _sine(3200.0 + sin(t * 40.0) * 200.0, t) * 0.05 * exp(-t * 12.0)
		shimmer += _sine(4800.0, t) * 0.03 * exp(-t * 28.0)
		s += shimmer * smoothstep(0.0, 0.02, t)

		_write_sample(bytes, i, s * 0.95)
	_play_pcm(bytes, -12.0)


## Ground / briar burst — short bomb thump + boom (not a gun).
func ground_bomb() -> void:
	var dur := 0.28
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var detune := 1.0 + randf_range(-0.05, 0.05)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var s := 0.0

		# Impact click (shell crack / dirt strike)
		var click_e := exp(-t * 90.0)
		s += _soft_noise() * 0.45 * click_e
		s += _sine(420.0 * detune, t) * 0.15 * click_e

		# Main bomb body — low sine boom with pitch drop
		var boom_f := lerpf(95.0, 38.0, clampf(t / 0.12, 0.0, 1.0)) * detune
		var boom_e := exp(-t * 9.0) * smoothstep(0.0, 0.008, t)
		s += _sine(boom_f, t) * 0.7 * boom_e
		s += _sine(boom_f * 1.5, t) * 0.25 * boom_e
		s += _sine(boom_f * 0.5, t) * 0.35 * boom_e

		# Mid "crump" body (dirt/explosion, not electric)
		var crump := _soft_noise() * 0.35 * exp(-t * 16.0)
		# Soft lowpass-ish by mixing slow noise
		crump += (randf() + randf() - 1.0) * 0.12 * exp(-t * 22.0)
		s += crump * smoothstep(0.0, 0.01, t)

		# Short rumble tail
		s += _sine(48.0 * detune, t) * 0.28 * exp(-t * 6.0) * smoothstep(0.02, 0.06, t)
		s += _sine(72.0 * detune, t) * 0.12 * exp(-t * 8.0)

		_write_sample(bytes, i, s * 0.85)
	_play_pcm(bytes, -9.0)


## Mortar / splash impact — heavier bomb.
func mortar_boom() -> void:
	var dur := 0.34
	var frames := int(SAMPLE_RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(SAMPLE_RATE)
		var s := 0.0
		var click_e := exp(-t * 70.0)
		s += _soft_noise() * 0.5 * click_e
		var boom_f := lerpf(78.0, 28.0, clampf(t / 0.15, 0.0, 1.0))
		var boom_e := exp(-t * 7.0) * smoothstep(0.0, 0.01, t)
		s += _sine(boom_f, t) * 0.75 * boom_e
		s += _sine(boom_f * 2.0, t) * 0.22 * boom_e
		s += _soft_noise() * 0.3 * exp(-t * 12.0)
		s += _sine(40.0, t) * 0.3 * exp(-t * 5.0)
		_write_sample(bytes, i, s * 0.85)
	_play_pcm(bytes, -8.0)


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
