import term.ui as tui
import rand

const (
	block_size = 1
	green      = tui.Color{0, 255, 0}
	grey       = tui.Color{150, 150, 150}
	white      = tui.Color{255, 255, 255}
	blue       = tui.Color{0, 0, 255}
	red        = tui.Color{255, 0, 0}
	black      = tui.Color{0, 0, 0}
)

enum Orientation {
	top
	right
	bottom
	left
}

enum GameState {
	pause
	main
	gameover
	game
}

struct Vec {
mut:
	x int
	y int
}

fn (v Vec) facing() Orientation {
	result := if v.x >= 0 {
		Orientation.right
	} else if v.x < 0 {
		Orientation.left
	} else if v.y >= 0 {
		Orientation.bottom
	} else {
		Orientation.top
	}
	return result
}

fn (mut v Vec) randomize(width int, height int) {
	v.x = rand.int_in_range(block_size, width - block_size)
	v.y = rand.int_in_range(block_size, height - block_size)
}

fn (mut v Vec) r_velocity(max_x int, max_y int) {
	v.x = rand.int_in_range(-1 * block_size, block_size)
	v.y = rand.int_in_range(-1 * block_size, block_size)
}

struct BodyPart {
mut:
	pos    Vec = {
	x: block_size
	y: block_size
}
	color  tui.Color = green
	facing Orientation = .top
}

struct Snake {
mut:
	app       &App
	direction Orientation
	body      []BodyPart
	velocity  Vec = Vec{
	x: 0
	y: 0
}
}

fn (s Snake) length() int {
	return s.body.len
}

fn (mut s Snake) impact(direction Orientation) {
	mut vec := Vec{}
	match direction {
		.top {
			vec.x = 0
			vec.y = -1 * block_size
		}
		.right {
			vec.x = block_size
			vec.y = 0
		}
		.bottom {
			vec.x = 0
			vec.y = block_size
		}
		.left {
			vec.x = -1 * block_size
			vec.y = 0
		}
	}
	s.direction = direction
	s.velocity = vec
}

fn (mut s Snake) move() {
	mut i := s.body.len - 1
	for i = s.body.len - 1; i >= 0; i-- {
		mut piece := s.body[i]
		if i > 0 {
			piece.pos = s.body[i - 1].pos
			piece.facing = s.body[i - 1].facing
		} else {
			/*
			piece.facing = direction
			
			match piece.facing {
				.top {
					piece.pos.y = if piece.pos.y > block_size { piece.pos.y - block_size } else { piece.pos.y }
				}
				.right {
					piece.pos.x = if piece.pos.x < s.app.width - block_size { piece.pos.x + block_size } else { piece.pos.x }
				}
				.bottom {
					piece.pos.y = if piece.pos.y < s.app.height - block_size { piece.pos.y + block_size } else { piece.pos.y }
				}
				.left {
					piece.pos.x = if piece.pos.x > block_size { piece.pos.x - block_size } else { piece.pos.x }
				}
			}
			*/
			piece.facing = s.direction
			piece.pos.x += s.velocity.x
			piece.pos.y += s.velocity.y
		}
		s.body[i] = piece
	}
}

fn (mut s Snake) grow() {
	head := s.get_tail()
	mut pos := Vec{}
	match head.facing {
		.bottom {
			pos.x = head.pos.x
			pos.y = head.pos.y - block_size
		}
		.left {
			pos.x = head.pos.x + block_size
			pos.y = head.pos.y
		}
		.top {
			pos.x = head.pos.x
			pos.y = head.pos.y + block_size
		}
		.right {
			pos.x = head.pos.x - block_size
			pos.y = head.pos.y
		}
	}
	s.body << BodyPart{
		pos: pos
		facing: head.facing
	}
}

fn (s Snake) get_body() []BodyPart {
	return s.body
}

fn (s Snake) get_head() BodyPart {
	return s.body[0]
}

fn (s Snake) get_tail() BodyPart {
	return s.body[s.body.len - 1]
}

fn (mut s Snake) randomize() {
	mut pos := s.get_head().pos
	pos.randomize(s.app.width, s.app.height)
	s.velocity.r_velocity(1, 1)
	s.direction = s.velocity.facing()
	s.body[0].pos = pos
}

fn (s Snake) check_overlap() bool {
	h := s.get_head()
	head_pos := h.pos
	for i in 3 .. s.length() {
		piece_pos := s.body[i].pos
		if head_pos.x == piece_pos.x && head_pos.y == piece_pos.y {
			return true
		}
	}
	return false
}

struct Rat {
mut:
	pos      Vec = {
	x: block_size
	y: block_size
}
	captured bool
	color    tui.Color = grey
	app      &App
}

fn (mut r Rat) randomize() {
	r.pos.randomize(r.app.width, r.app.height)
}

struct App {
mut:
	tui    &tui.Context = 0
	snake  Snake
	rat    Rat
	width  int
	height int
	redraw bool = true
	state  GameState = .game
}

fn init(x voidptr) {
	mut app := &App(x)
	w, h := app.tui.window_width, app.tui.window_height
	app.width = w
	app.height = h
	mut snake := Snake{
		body: []BodyPart{len: 1, init: BodyPart{}}
		app: app
	}
	snake.randomize()
	mut rat := Rat{
		app: app
	}
	rat.randomize()
	app.snake = snake
	app.rat = rat
}

fn event(e &tui.Event, x voidptr) {
	mut app := &App(x)
	match e.typ {
		.mouse_down {}
		.mouse_drag {}
		.mouse_up {}
		.key_down {
			match e.code {
				.up, .w { app.move_snake(.top) }
				.down, .s { app.move_snake(.bottom) }
				.left, .a { app.move_snake(.left) }
				.right, .d { app.move_snake(.right) }
				.c {}
				.escape { exit(0) }
				else { exit(0) }
			}
			if e.code == .c {
			}
			else if e.code == .escape {
				exit(0)
			}
		}
		else {}
	}
	app.redraw = true
}

fn (mut a App) update() {
	a.snake.move()
	overlap := a.snake.check_overlap()
	if overlap {
		a.state = .gameover
	}
}

fn frame(x voidptr) {
	mut app := &App(x)
	if !app.redraw {
		return
	}
	app.tui.clear()
	app.update()
	if app.state == .gameover {
		app.draw_gameover()
		app.redraw = false
	} else {
		app.draw_score()
		app.draw_rat()
		app.draw_snake()
		$if verbose ? {
			app.draw_debug()
		}
		if app.check_capture() {
			app.rat.randomize()
			app.snake.grow()
		}
	}
	app.tui.reset_bg_color()
	app.tui.flush()
}

fn (mut a App) move_snake(direction Orientation) {
	a.snake.impact(direction)
}

fn (mut a App) draw_snake() {
	for part in a.snake.get_body() {
		a.tui.set_bg_color(part.color)
		text := match part.facing {
			.top { '^' }
			.bottom { 'v' }
			.right { '>' }
			.left { '<' }
		}
		a.tui.draw_rect(part.pos.x, part.pos.y, part.pos.x + block_size, part.pos.y + block_size)
		a.tui.set_color(white)
		a.tui.draw_text(part.pos.x, part.pos.y, text)
	}
}

fn (mut a App) draw_rat() {
	a.tui.set_bg_color(a.rat.color)
	a.tui.draw_rect(a.rat.pos.x, a.rat.pos.y, a.rat.pos.x + block_size, a.rat.pos.y + block_size)
}

fn (a App) check_capture() bool {
	snake_pos := a.snake.get_head().pos
	rat_pos := a.rat.pos
	return snake_pos.x < rat_pos.x + block_size &&
		snake_pos.x + block_size > rat_pos.x && snake_pos.y < rat_pos.y + block_size && snake_pos.y +
		block_size > rat_pos.y
}

fn (mut a App) draw_score() {
	a.tui.set_bg_color(grey)
	a.tui.set_color(blue)
	score := a.snake.length() - 1
	a.tui.draw_text(a.width - (2 * block_size), block_size, '${score:03d}')
}

fn (mut a App) draw_debug() {
	a.tui.set_color(blue)
	a.tui.set_bg_color(grey)
	snake := a.snake
	rat := a.rat
	a.tui.draw_text(block_size, block_size, 'Vx: ${snake.velocity.x:+02d} Vy: ${snake.velocity.y:+02d}')
	a.tui.draw_text(block_size, 2 * block_size, 'F: $snake.direction')
	snake_head := snake.get_head()
	a.tui.draw_text(block_size, 4 * block_size, 'Sx: ${snake_head.pos.x:+03d} Sy: ${snake_head.pos.y:+03d}')
	a.tui.draw_text(block_size, 5 * block_size, 'Rx: ${rat.pos.x:+03d} Ry: ${rat.pos.y:+03d}')
}

fn (mut a App) draw_gameover() {
	a.tui.set_bg_color(white)
	a.tui.draw_rect(0, 0, a.width, a.height)
	a.tui.set_color(red)
	a.tui.set_bg_color(black)
	a.snake.body.clear()
	a.rat.pos = Vec{
		x: -1
		y: -1
	}
	a.tui.draw_text(block_size, block_size, '   #####                         #######                       ')
	a.tui.draw_text(block_size, 2 * block_size, '  #     #   ##   #    # ######   #     # #    # ###### #####   ')
	a.tui.draw_text(block_size, 3 * block_size, '  #        #  #  ##  ## #        #     # #    # #      #    #  ')
	a.tui.draw_text(block_size, 4 * block_size, '  #  #### #    # # ## # #####    #     # #    # #####  #    #  ')
	a.tui.draw_text(block_size, 5 * block_size, '  #     # ###### #    # #        #     # #    # #      #####   ')
	a.tui.draw_text(block_size, 6 * block_size, '  #     # #    # #    # #        #     #  #  #  #      #   #   ')
	a.tui.draw_text(block_size, 6 * block_size, '   #####  #    # #    # ######   #######   ##   ###### #    #  ')
}

mut app := &App{}
app.tui = tui.init({
	user_data: app
	event_fn: event
	frame_fn: frame
	init_fn: init
	hide_cursor: true
	frame_rate: 15
})
app.tui.run()
