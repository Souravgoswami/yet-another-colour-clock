#!/usr/bin/ruby -W0
# Written by Sourav Goswami
# GNU General Public License v3.0

require 'ruby2d'
on :key_down do |k| raise SystemExit if %w(escape space).include? k.key end

file = File.open('configure.conf').readlines
conversion = ->(option) { file.select { |opt| opt.strip.start_with?(option) }[-1].split('=')[-1].strip }

Custom_Title = conversion.call('Custom_Title =')
Borderless = conversion.call('Border =').downcase == 'true' || conversion.call('Border =').empty?
Resizable = conversion.call('Resizable =').downcase == 'true' || conversion.call('Resizable =').empty?

Width, Height = conversion.call('Width =').to_i, conversion.call('Height =').to_i
FPS = conversion.call('FPS =').to_i

Font = conversion.call('Font =')
Font_Size = conversion.call('Font_Size =').to_i

Day_Font_Colour = conversion.call('Day_Font_Colour =')
Time_Font_Colour = conversion.call('Time_Font_Colour =')
Date_Font_Colour = conversion.call('Date_Font_Colour =')

Font_Opacity = conversion.call('Font_Opacity =').to_f

Magic_Particles = conversion.call('Magic_Particles =').to_i

Deers = conversion.call('Deers =').to_i
Reverse_Deers = conversion.call('Reverse_Deers =').to_i
Birds = conversion.call('Birds =').to_i

Show_Sun = conversion.call('Show_Sun =') == 'true' || conversion.call('Show_Sun =').empty?
Sky1, Sky2, Sky3 = conversion.call('Sky1 ='), conversion.call('Sky2 ='), conversion.call('Sky3 =')

Sky1_Quality = conversion.call('Sky1_Quality =').to_i

Leaves = conversion.call('Leaves =').to_i
Snow = conversion.call('Snow =').to_i

Custom_Message = conversion.call('Custom_Message =')
Custom_Message_Font_Colour = conversion.call('Custom_Message_Font_Colour =')
Custom_Text_Font_Opacity = conversion.call('Custom_Text_Font_Opacity =').to_f
Custom_Message_Font_Size = conversion.call('Custom_Message_Font_Size =').to_i

Custom_Image = conversion.call('Font =')
Custom_Image_Width= conversion.call('Custom_Image_Width =').to_i
Custom_Image_Height = conversion.call('Custom_Image_Height =').to_i
Custom_Image_Opacity = conversion.call('Custom_Image_Opacity =').to_i

module Ruby2D
	def change_colour=(arg)
		opacity_ = self.opacity
		self.color, self.opacity = arg, opacity_
	end
end

class Ruby2D::Sprite
	def contains?(object)
		x, y = object.x, object.y
		@x <= x && @x + @clip_width >= x && @y <= y && @y + @height >= y
	end
end

def main
	$width, $height = Width, Height
	$width, $height = 1280, 720 if Width <= 0 || Height <= 0

	custom_title = Custom_Title
	custom_title = 'Yet Another Colour Clock' if Custom_Title.empty?

	set title: custom_title, width: $width, height: $height, background: 'ffffff', resizable: true, fps_cap: $fps
	$fps = FPS
	$fps = 50 if FPS <= 0

	time = proc { |format='%H:%M:%S'| Time.new.strftime(format) }
	highlighted = ->(object, threshold=0.6) { object.opacity -= 0.05 if object.opacity > threshold }
	not_highlighted = ->(object, threshold=1) { object.opacity += 0.05 if object.opacity < threshold }

	sky1, sky2, sky3 = Sky1, Sky2, Sky3
	sky1 = '#3c4fcb' if Sky1.empty?
	sky2 = '#f173ac' if Sky2.empty?
	sky3 = '#ffe070' if Sky3.empty?

	img = Image.new 'images/silhoutte.png', z: 100, width: $width, height: $height
	img.x, img. y = 0, $height - img.height

	bgcolor = ['#ffffff', '#ffffff', sky3, sky2]
	bg = Rectangle.new color: bgcolor, width: $width, height: $height, z: -1000

	sky1_quality = Sky1_Quality
	sky1_quality = 2 if Sky1_Quality <= 0.1

	blue_sky = []
	0.step($height, sky1_quality) do |temp|
		c = Line.new x1: 0, x2: $width, y1: temp, y2: temp, width: sky1_quality, color: sky1, z: -1000
		c.opacity -= temp.to_f/$width * 2.5
		blue_sky << c
	end

	stars = []
	((blue_sky.size - 1)/2).times do |temp|
			s = Square.new(size: rand(2.0..4), x: rand(0.0..$width.to_f), y: blue_sky[temp].y1)
			s.opacity = blue_sky[temp].opacity
			stars << s
	end

	particles, particles_speed = [], []
	Magic_Particles.times do
		particles << Square.new(size: rand(1.0..3.0), x: rand(0..$width), y: $height, z: -1, color: %w(#ffffff #ffff00).sample)
		particles_speed << rand(4.0..10.0)
	end

	sun_touched = false

	sun_enum = ($width/50).step(1, -1)
	sun, sun_circles = [], []
	if Show_Sun
		sun_enum.each.with_index do |temp, i|
			circle = Image.new 'images/sun.png', width: temp * 3.0, height: temp * 3.0, z: -998, x: $width/1.2 + i * 1.5, y: $height/2.0 + i * 1.5
			circle.color = temp < sun_enum.size/1.3 ? '#ffffff' : '#ffef00'
			circle.opacity = temp/(sun_enum.size * 5.0) if temp >= 10
			sun << circle
		end

		sun_enum.each do |i|
			circle = Circle.new x: sun.last.x, y: sun.last.y, z: -999, color: '#ffff00', radius: i * 1.5
			circle.opacity = i/(sun_enum.size * 50.0)
			sun_circles << circle
		end
	end

	no_snow = Snow
	snow = []
	no_snow.times do
		size = rand(1.0..8)
		snow << Image.new('images/snow.png', x: rand(0..$width), y: rand(0..$height), width: size, height: size)
	end

	tree1 = Image.new 'images/trees/1.png', width: $width/5, height: $height/3.0
	tree1.x, tree1.y = $width/2 - tree1.width/2, $height - tree1.height * 1.3

	tree2 = Image.new 'images/trees/2.png', width: $width/5, height: $height/3.0
	tree2.x, tree2.y = $width/10.0, tree1.y + 5

	leaves1, leaves2 = [], []
	falling_speed = []
	leaves1_rotate, leaves2_rotate = [], []
	rotate = 0.step(360, 15).each.to_a

	no_leaves = Leaves

	no_leaves.times do
		leaf = Image.new 'images/leaves/1.png', x: rand(tree1.x..tree1.x + tree1.width), z: tree1.z + 1, rotate: 0.step(360, 15).to_a.sample
		leaf.y = tree1.y + tree1.height/2
		leaf.rotate = rotate.sample
		leaves1 << leaf

		leaf = Image.new 'images/leaves/1.png', x: rand(tree1.x..tree1.x + tree1.width), z: tree1.z + 1, rotate: 0.step(360, 15).to_a.sample
		leaf.x, leaf.y = rand(tree2.x..tree2.x + tree2.width), rand(tree2.y + tree2.height/2..tree2.y + tree2.height)
		leaf.rotate = rotate.sample
		leaves2 << leaf

		falling_speed << rand(0.5..1.0)
	end

	no_birds = Birds
	birds, bird_speeds = [], []
	no_birds.times do
		speed = rand(10.0..30.0)
		size = rand($width/80..$width/60)
		bird = Sprite.new 'images/birds/1.png', time: speed, loop: true, clip_width: 110, color: 'black', width: size, height: [size].sample
		bird.x, bird.y, bird.z= rand(0..$width), rand(0.0..blue_sky[blue_sky.size/2].y1), [-1001, 0].sample
		bird.play
		birds << bird
		bird_speeds << speed/10.0
	end

	deers, deer_speeds = [], []
	Deers.times do
		speed = rand(8.0..16.0)
		deer = Sprite.new('images/deer.png', clip_width: 134, time: speed, loop: true, x: rand(0..$width))
		deer.y = $height - deer.clip_height
		deer.play
		deers << deer
		deer_speeds << speed/2.0
	end

	rev_deers, rev_deer_speeds = [], []
	Reverse_Deers.times do
		speed = rand(8.0..16.0)
		deer = Sprite.new('images/deer_reverse.png', clip_width: 134, time: speed, loop: true, x: rand(0..$width))
		deer.y = $height - deer.clip_height
		deer.play
		rev_deers << deer
		rev_deer_speeds << speed/2.0
	end

	bird_touched = nil
	on :mouse_move do |e|
		birds.each do |val|
			if val.contains?(e)
				bird_touched = val
				break
			end
		end
	end

	custom_image, custom_image_width, custom_image_height = Custom_Image, Custom_Image_Width, Custom_Image_Height
	custom_image_opacity = Custom_Image_Opacity

	custom_image_opacity = Custom_Image_Opacity
	custom_image, custom_image_width, custom_image_height, custom_image_opacity = 'images/snow.png', 0, 0, 0 if Custom_Image.empty? || !File.exist?(Custom_Image)

	custom_image = Image.new custom_image, z: 100

	custom_image_width = custom_image.width if custom_image_width <= 0
	custom_image_height = custom_image.height if custom_image_height <= 0

	custom_image.opacity = custom_image_opacity
	custom_image.width, custom_image.height = custom_image_width, custom_image_height

	custom_image_touched, custom_image_pressed = false, false

	message = Custom_Message
	message = '' if Custom_Message.empty?

	custom_message_font_colour = Custom_Message_Font_Colour
	custom_message_font_colour = '#ffffff' if Custom_Message_Font_Colour.empty?

	custom_message_font_size = Custom_Message_Font_Size
	custom_message_font_size = 20 if Custom_Message_Font_Size <= 0

	font = Font
	font = "fonts/Gafata/Gafata-Regular.ttf" if Font.empty?

	font_size = Font_Size
	font_size = 100 if Font_Size <= 0

	day_font_colour = Day_Font_Colour
	day_font_colour = '#ffffff' if Day_Font_Colour.empty?

	time_font_colour = Time_Font_Colour
	time_font_colour = '#ffffff' if Time_Font_Colour.empty?

	date_font_colour = Date_Font_Colour
	date_font_colour = '#ffffff' if date_font_colour.empty?

	font_opacity = Font_Opacity
	font_opacity = 1 if Font_Opacity <= 0

	custom_text_font_opacity = Custom_Text_Font_Opacity
	custom_text_font_opacity = 1 if Custom_Text_Font_Opacity <= 0

	custom_message_touched, custom_message_pressed = false, false
	custom_text = Text.new message, font: font, z: 100, size: custom_message_font_size, color: custom_message_font_colour
	custom_text.x, custom_text.opacity = $width/2.0 - custom_text.width/2.0, custom_text_font_opacity

 	time_text = Text.new time.call + ':' + time.call('%N')[0..1], font: font, z: 100, size: font_size, color: time_font_colour

	time_text.x, time_text.y, time_text.opacity = $width/2 - time_text.width/2, $height/3 - time_text.height, font_opacity
	time_text_width = time_text.width
	time_text_touched = false

	time_highlighted, time_text_pressed = false, false

	date_text = Text.new time.call('%D'), font: font, size: font_size/2.0, z: 100, color: date_font_colour
	date_text_width = date_text.width
	date_text.x, date_text.y, date_text.opacity = $width/2 - date_text.width/2, time_text.y + time_text.height, font_opacity

	date_highlighted, date_text_pressed = false, false

	day_text = Text.new time.call('%A'), font: font, size: font_size/1.5, z: 100, color: day_font_colour
	day_text.x, day_text.y, day_text.opacity = $width/2 - day_text.width/2, date_text.y + day_text.height, font_opacity

	day_text_highlighted, day_text_pressed = false, false

	on :mouse_move do |e|
		day_text_highlighted = day_text.contains?(e.x, e.y) ? true : false
		time_highlighted = time_text.contains?(e.x, e.y) ? true : false
		date_highlighted = date_text.contains?(e.x, e.y) ? true : false
		custom_message_touched = custom_text.contains?(e.x, e.y) ? true : false

		if sun_touched
			sun.each_with_index { |val, i| val.x, val.y = e.x + i * 1.5, e.y + i * 1.5 }
			sun_circles.each { |val| val.x, val.y = sun.last.x + 1, sun.last.y + 1 }
		end

		day_text.x, day_text.y = e.x - day_text.width/2.0, e.y - day_text.height/2.0 if day_text_pressed
		time_text.x, time_text.y = e.x - time_text_width/2.0, e.y - time_text.height/2.0 if time_text_pressed
		date_text.x, date_text.y = e.x - date_text.width/2.0, e.y - date_text.height/2.0 if date_text_pressed

		custom_text.x, custom_text.y = e.x - custom_text.width/2.0, e.y - custom_text.height/2.0 if custom_message_pressed
		custom_image.x, custom_image.y = e.x - custom_image.width/2.0, e.y - custom_image.height/2.0 if custom_image_pressed
	end

	on :mouse_down do |e|
		if time_text.contains?(e.x, e.y) then time_text_pressed = true
			elsif day_text.contains?(e.x, e.y) then day_text_pressed = true
			elsif date_text.contains?(e.x, e.y) then date_text_pressed = true
			elsif custom_text.contains?(e.x, e.y) then custom_message_pressed = true
			elsif custom_image.contains?(e.x, e.y) then custom_image_pressed = true
		end

		sun.each { |val|
			if val.contains?(e.x, e.y)
				sun_touched = true
				break
			end
		}

		time_text_pressed, date_text_pressed, custom_message_pressed, sun_touched = false, false, false, false if e.button == :right
		bg.color = bgcolor.rotate! if e.button == :middle
	end

	on :mouse_up do |e|
		day_text_pressed, time_text_pressed, date_text_pressed, custom_message_pressed = false, false, false, false
		custom_image_pressed, sun_touched = false, false
	end

	on :mouse_scroll do |e|

		if get(:mouse_y) >= $height/2
			bg.opacity -= 0.05 if e.delta_y == 1 and bg.opacity > 0
			bg.opacity += 0.05 if e.delta_y == -1 and bg.opacity < 1
		else
			blue_sky.each do |val|
				val.opacity -= 0.05 if e.delta_y == 1
				val.opacity += 0.05 if e.delta_y == -1
			end
		end
	end

	air_direction = [-1, 0, 1].sample
	air_change = air_direction
	sun_occilation = 0
	counter = 0
	leaves_size = leaves1.size

	sun_opacity_control = 0.01
	update do
		counter += 1

		sun_circles.each do |val|
			if val.opacity <= 0
				sun_opacity_control = 0.01
			elsif val.opacity >= 0.5
				sun_opacity_control = -0.01
			end
			val.opacity += sun_opacity_control
		end

		day_text_highlighted ? highlighted.call(day_text) : not_highlighted.call(day_text, font_opacity)
		time_highlighted ? highlighted.call(time_text) : not_highlighted.call(time_text, font_opacity)
		date_highlighted ? highlighted.call(date_text) : not_highlighted.call(date_text, font_opacity)
		custom_message_touched ? highlighted.call(custom_text) : not_highlighted.call(custom_text, custom_text_font_opacity)

		time_text.text = time.call + ':' + time.call('%N')[0..1]
		date_text.text = time.call('%D')

		air_direction = [-1, 0, 1].sample if Time.new.strftime('%s').to_i % 5 == 0 and counter % $fps == 0
		stars.sample.z = [-1001, [-500] * 3].flatten.sample

		snow.each_with_index do |val, i|
			val.x += air_direction
			val.opacity -= 0.003
			val.y += val.width - val.width/1.5

			val.x, val.y, val.opacity = rand(0..$width), 0, 1 if val.y > $height
		end

		bird_speeds[birds.index(bird_touched)] = 10 if bird_touched

		birds.each_with_index do |val, i|
			val.x += bird_speeds[i]
			val.y += Math.sin(counter/bird_speeds[i])
			if val.x >= $width + val.width
				bird_speeds[i] = rand(1.0..3.0)
				val.x, val.y = -val.width, rand(0..blue_sky[blue_sky.size/2].y1)
				size = rand(10.0..30.0)
				val.width, val.height = size, [size, size/1.5].sample
				val.z = [-1001, 0].sample
				bird_touched = nil if bird_touched.equal?(val)
			end
		end

		deers.each_with_index do |val, i|
			val.x += deer_speeds[i]
			if val.x >= $width + val.clip_width
				val.x = -val.clip_width
				val.z = [-1001, [0] * 3].flatten.sample
				deer_speeds[i] = rand(8.0..16.0)
			end
		end

		rev_deers.each_with_index do |val, i|
			val.x -= rev_deer_speeds[i]
			if val.x <= -val.clip_width
				val.x = $width + val.clip_width
				val.z = [-1001, [0] * 3].flatten.sample
				rev_deer_speeds[i] = rand(8.0..16.0)
			end
		end

		leaves_size.times do |i|
			val, val2 = leaves1[i], leaves2[i]

			val.rotate += falling_speed[i] * 2.0
			val2.rotate += falling_speed[i] * 2.0

			if air_direction == 0
				val.x += Math.sin(counter/10.0)
				val.y += Math.cos(counter/5.0) + falling_speed[i]

				val2.x += Math.sin(counter/10.0)
				val2.y += Math.cos(counter/5.0) + falling_speed[i]
			else
				val.x += Math.sin(counter/20.0) + air_direction
				val.y += Math.cos(counter/20.0) + falling_speed[i]

				val2.x += Math.sin(counter/20.0) + air_direction
				val2.y += Math.cos(counter/20.0) + falling_speed[i]
			end

			val.x, val.y, val.opacity = rand(tree1.x..tree1.x + tree1.width), tree1.y + tree1.height/2, [0, 1].sample if val.y > tree1.y + tree1.height
			val2.x, val2.y, val.opacity = rand(tree2.x..tree2.x + tree2.width), (tree2.y + tree2.height/2), [0, 1].sample if val2.y > tree2.y + tree2.height
		end

		particles.each_with_index do |val, i|
			val.y -= particles_speed[i]
			val.x += Math.sin(i)
			val.change_colour = %w(#ffffff #ffff00).sample
			val.opacity -= 0.015
			if val.y <= $height/1.5
				val.x, val.y, val.opacity = rand(0..$width), $height, 1
			end
		end
	end
	show
end

begin
	main

rescue SystemExit
	puts "Have a great day!"

rescue Exception => e
	puts "Some weird error just happened"
	puts "Feel free to contact the developer <souravgoswami@protonmail.com>\n"
	puts "Tell him about:\n\n"

	puts e
	puts e.backtrace
	abort
end
