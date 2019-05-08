#!/usr/bin/env ruby
# Written by Sourav Goswami
# GNU General Public License v3.0
require('ruby2d')
PATH = File.dirname(__FILE__)

config = IO.readlines(File.join(PATH, 'configure.conf'))
conversion = ->(option) { config.select { |opt| opt.strip.start_with?(option) }[-1].to_s.split('=')[-1].to_s.strip }

%w(Custom_Title Custom_Message Custom_Message_Font_Colour Custom_Image Day_Font_Colour Time_Font_Colour Date_Font_Colour
	Font Sky1 Sky2 Sky3).each { |const| eval("#{const} = conversion.(%Q(#{const} =))") }

%w(Width Height Custom_Text_Font_Opacity FPS Font_Size Magic_Particles Deers Reverse_Deers Birds Sky1_Quality Leaves Snow Custom_Message_Font_Size
	Custom_Image_Width Custom_Image_Height Custom_Image_Opacity).each { |const| eval("#{const} = conversion.(%q(#{const} =)).to_i") }

Borderless = conversion.call('Border =').downcase == 'true' || conversion.call('Border =').empty?
Resizable = conversion.call('Resizable =').downcase == 'true' || conversion.call('Resizable =').empty?
Show_Sun = conversion.call('Show_Sun =') == 'true' || conversion.call('Show_Sun =').empty?
Font_Opacity = conversion.call('Font_Opacity =').to_f

module Ruby2D def contain?(object) contains?(object.x, object.y) end end

define_method(:main) do
	$width, $height = (Width <= 0 || Height <= 0) ? [1280, 720] : [Width, Height]
	set(width: $width, height: $height, background: 'ffffff', resizable: true, fps_cap: ($fps = FPS <= 0 ? 50 : FPS), title: Custom_Title.empty? ? 'Yet Another Colour Clock' : Custom_Title)

	time = proc { |format='%H:%M:%S'| Time.new.strftime(format) }
	highlighted = ->(object, threshold = 0.25) { object.opacity -= 0.075 if object.opacity > threshold }
	not_highlighted = ->(object, threshold = 1) { object.opacity += 0.075 if object.opacity < threshold }

	img = Image.new(File.join(PATH, 'images', 'silhoutte.png'), z: 100, width: $width, height: $height)
	img.x, img. y = 0, $height - img.height

	sky1 = Sky1.empty? ? '#3c4fcb' : Sky1
	bgcolor = '#ffffff', '#ffffff', Sky3.empty? ? '#ffe070' : Sky3, Sky2.empty? ? '#f173ac' : Sky2
	bg = Rectangle.new color: bgcolor, width: $width, height: $height, z: -1000

	sq1 = Sky1_Quality <= 0.1 ? 2 : Sky1_Quality
	blue_sky = Array.new($height / sq1) { |t| Line.new(x2: $width, y1: t * sq1, y2: t * sq1, width: sq1, color: sky1, z: -1000, opacity:  1 - (t.to_f * sq1) / $width * 2.5) }

	stars = Array.new((blue_sky.size - 1)/2) { |temp| Square.new(size: rand(2.0..4), x: rand($width.to_f), y: blue_sky[temp].y1, opacity: blue_sky[temp].opacity) }
	snow = Array.new(Snow) { Image.new(File.join(PATH, 'images', 'snow.png'), x: rand(0..$width), y: rand(0..$height), width: (size = rand(1.0..8)), height: size) }
	particles_size = (particles = Array.new(Magic_Particles) { Square.new(size: rand(1.0..3.0), x: rand($width), y: $height, z: -1, color: '#ffffff') }).size

	sun_touched, sun_enum = false, ($width / 50).step(1, -1)
	sun =  if Show_Sun
		sun_enum.map.with_index do |temp, i|
			Image.new(
				File.join(PATH, 'images', 'sun.png'), width: temp * 3.0, height: temp * 3.0, z: -998, x: $width/1.2 + i * 1.5, y: $height/2.0 + i * 1.5,
				color: temp < sun_enum.size / 1.5 ? '#ffffff' : '#ffef00', opacity: (temp >= 10 ? temp / (sun_enum.size * 5.0) : 1)
			)
		end
	else
		[]
	end

	tree1 = Image.new(File.join(PATH, %w(images trees 1.png)), width: $width/5, height: $height/3.0)
	tree2 = Image.new File.join(PATH, %w(images trees 2.png)), width: $width/5, height: $height/3.0
	tree1.x, tree1.y = $width/2 - tree1.width/2, $height - tree1.height * 1.3
	tree2.x, tree2.y = $width/10.0, tree1.y + 5

	leaves1, leaves2, falling_speed, rotate = [], [], Array.new(Leaves) { rand(0.5..1) }, 0.step(360, 15).to_a
	Leaves.times do
		leaves1.push(Image.new(File.join(PATH, %w(images  leaf.png)), x: rand(tree1.x..tree1.x + tree1.width), y: tree1.y + tree1.height / 2, z: tree1.z + 1, rotate: rotate.sample))
		leaves2.push(Image.new(File.join(PATH, %w(images leaf.png)), x: rand(tree2.x..tree2.x + tree2.width), y: tree2.y + tree2.height / 2, z: tree1.z + 1, rotate: rotate.sample))
	end

	bird_touched, bird_speeds = nil, Array.new(Birds) { rand(1.0..3.0) }
	birds = Array.new(Birds) do
		bird = Sprite.new(File.join(PATH, %w(images birds.png)), time: rand(10.0..30.0) , loop: true, clip_width: 110, color: '#000000', width: (size = rand($width/80..$width/60)), height: size)
		bird.x, bird.y, bird.z = rand($width), rand(blue_sky[blue_sky.size/2].y1), [-1001, 0].sample
		bird.play
		bird
	end

	deer_speeds = []
	deers = Array.new(Deers) do
		speed = rand(8.0..16.0)
		deer_speeds.push(speed / 2.0)
		deer = Sprite.new(File.join(PATH, %w(images deer.png)), clip_width: 134, time: speed, loop: true, x: rand(0..$width))
		deer.y = $height - deer.clip_height
		deer.play
		deer
	end

	rev_deer_speeds = []
	rev_deers = Array.new(Reverse_Deers) do
		speed = rand(8.0..16.0)
		rev_deer_speeds << speed / 2.0
		deer = Sprite.new(File.join(PATH, %w(images deer_reverse.png)), clip_width: 134, time: speed, loop: true, x: rand(0..$width))
		deer.y = $height - deer.clip_height
		deer.play
		deer
	end

	if Custom_Image.empty? || !File.readable?(Custom_Image)
		Warning.warn "#{Custom_Image} doesn't exist. Please mention a proper path and make sure the file exists." if !File.exist?(Custom_Image) && !Custom_Image.empty?
		custom_image = Image.new(File.join(PATH, %w(images snow.png)), z: -10000, width: 0, height: 0)
	else
		custom_image = Image.new(Custom_Image, z: -1000)
		custom_image.width = Custom_Image_Width <= 0 ? custom_image.width : Custom_Image_Width
		custom_image.height = Custom_Image_Height <= 0 ? custom_image.height : Custom_Image_Height
		custom_image.opacity = Custom_Image_Opacity <= 0 ? 1 : Custom_Image_Opacity
	end

	font = Font.empty? ? File.join(PATH, %w(fonts Gafata Gafata-Regular.ttf)) : Font
	font_size = Font_Size <= 0 ? 100 : Font_Size
	font_opacity = Font_Opacity <= 0 ? 1 : Font_Opacity

	custom_text = Text.new Custom_Message.empty? ? '' : Custom_Message, font: font, z: 100, size: Custom_Message_Font_Size <= 0 ? 20 : Custom_Message_Font_Size,
		color: Custom_Message_Font_Colour.empty? ? '#ffffff' : Custom_Message_Font_Colour, opacity: Custom_Text_Font_Opacity <= 0 ? 1 : Custom_Text_Font_Opacity
	custom_text.x = $width / 2.0 - custom_text.width / 2.0

 	time_text = Text.new time.call + ':' + time.call('%N')[0..1], font: font, z: 100, size: font_size, color: Time_Font_Colour.empty? ? '#ffffff' : Time_Font_Colour
	time_text.x, time_text.y, time_text.opacity = $width/2 - time_text.width/2, $height/3 - time_text.height, font_opacity

	date_text = Text.new time.call('%D'), font: font, size: font_size/2.0, z: 100, color: Date_Font_Colour.empty? ? '#ffffff' : Date_Font_Colour
	date_text.x, date_text.y, date_text.opacity = $width / 2 - date_text.width / 2, time_text.y + time_text.height, font_opacity

	day_text = Text.new time.call('%A'), font: font, size: font_size / 1.5, z: 100, color: Day_Font_Colour.empty? ? '#ffffff' : Day_Font_Colour
	day_text.x, day_text.y, day_text.opacity = $width/2 - day_text.width/2, date_text.y + day_text.height, font_opacity

	touched_obj = pressed_obj = nil
	touchable_objects = [time_text, day_text, date_text, custom_text, custom_image]

	on :mouse_move do |e|
		touchable_objects.each { |el| el.contain?(e) ? (( touched_obj = el) && (break)) : touched_obj = nil  }
		sun.each_with_index { |val, i| val.x, val.y = e.x + i * 1.5, e.y + i * 1.5 } if sun_touched
		pressed_obj.x, pressed_obj.y = e.x - pressed_obj.width / 2, e.y - pressed_obj.height / 2 if pressed_obj
	end

	on :mouse_down do |e|
		touchable_objects.each { |el| el.contain?(e) ? ((pressed_obj = el) && break) : pressed_obj = nil }
		sun.each { |val| ((sun_touched = true) && (break)) if val.contains?(e.x, e.y) }
		bg.color = bgcolor.rotate! if e.button == :middle
		pressed_obj = nil if e.button == :right
	end

	on(:key_down) { |k| raise SystemExit if %w(escape space).include? k.key }
	on(:mouse_move) { |e| birds.each { |val| (bird_touched = val) && (break) if val.contain?(e) } }
	on(:mouse_up) { pressed_obj, sun_touched = nil, false }

	on :mouse_scroll do |e|
		if get(:mouse_y) >= $height / 2
			bg.opacity -= 0.05 if e.delta_y == 1 and bg.opacity > 0
			bg.opacity += 0.05 if e.delta_y == -1 and bg.opacity < 1
		else
			blue_sky.each { |val| val.opacity = val.opacity.method(e.delta_y == 1 ? :- : :+).(0.05) }
		end
	end

	air_direction, counter, leaves_size = [-1, 0, 1].sample, 0, leaves1.size

	update do
		counter += 1
		touched_obj ? touchable_objects.each { |o| o.equal?(touched_obj) ? highlighted.(touched_obj) : not_highlighted.(o) } : touchable_objects.each { |o| not_highlighted.(o) }
		pressed_obj ? touchable_objects.each { |o| o.equal?(pressed_obj) ? highlighted.(pressed_obj) : not_highlighted.(o) } : ''

		time_text.text, date_text.text = time.call + ':' + time.call('%N')[0..1], time.('%D')

		air_direction = [-1, 0, 1].sample if Time.new.strftime('%s').to_i % 5 == 0 and counter % $fps == 0
		stars.sample.z = [-1001, [-500] * 3].flatten.sample

		snow.each_with_index do |val, i|
			val.x, val.y, val.opacity = val.x + air_direction, val.y + val.width / 2.0, val.opacity - 0.005
			val.x, val.y, val.opacity = rand(0..$width), 0, 1 if val.y > $height
		end

		bird_speeds[birds.index(bird_touched)] = 10 if bird_touched

		birds.each_with_index do |val, i|
			val.x, val.y = val.x + bird_speeds[i], val.y + Math.sin(counter / bird_speeds[i])
			if val.x >= $width + val.width
				bird_speeds[i] = rand(1.0..3.0)
				val.x, val.y, val.z = -val.width, rand(blue_sky[blue_sky.size/2].y1), [-1001, 0].sample
				val.width, val.height = (size = rand(10.0..30.0)), [size, size / 1.5].sample
				bird_touched = nil if bird_touched.equal?(val)
			end
		end

		deers.each_with_index do |val, i|
			val.x += deer_speeds[i]
			val.x, val.opacity = -val.clip_width, [0, 1].sample if val.x >= $width + val.clip_width
		end

		rev_deers.each_with_index do |val, i|
			val.x -= rev_deer_speeds[i]
			val.x, val.opacity = $width, [0, 1].sample if val.x <= -val.clip_width
		end

		leaves_size.times do |i|
			val, val2, fspeed = leaves1[i], leaves2[i], falling_speed[i]
			val.rotate, val2.rotate = val.rotate + fspeed * 2.0, val2.rotate + fspeed * 2.0

			x, y = air_direction == 0 ? [Math.sin(counter / 10.0), Math.cos(counter / 5.0) + fspeed] : [Math.sin(counter / 20.0), Math.cos(counter / 20.0) + fspeed]
			val.x, val.y, val2.x, val2.y = val.x + x, val.y + y, val2.x + x, val2.y + y

			val.x, val.y, val.opacity = rand(tree1.x..tree1.x + tree1.width), tree1.y + tree1.height/2, [0, 1].sample if val.y > tree1.y + tree1.height
			val2.x, val2.y, val.opacity = rand(tree2.x..tree2.x + tree2.width), (tree2.y + tree2.height/2), [0, 1].sample if val2.y > tree2.y + tree2.height
		end

		particles.each_with_index do |val, i|
			val.x, val.y, val.opacity = val.x + Math.sin(i), val.y - i / (particles_size / 8.0), val.opacity - 0.015
			val.x, val.y, val.opacity = rand($width), $height, 1 if val.y <= $height/1.5
		end
	end
end

begin
	main
	show
rescue SystemExit
	puts "Have a great day!"
rescue Exception => e
	Kernel.warn(e)
end
