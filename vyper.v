import term.ui as tui
import rand

const (
	block_size = 1
	green = tui.Color{0, 255, 0}
	grey = tui.Color{150, 150, 150}
	white = tui.Color{255, 255, 255}
	
	blue = tui.Color{0, 0, 255}
)

enum Orientation {
	top right bottom left
}

struct Vec {
	mut:
	x int
	y int
}

struct BodyPart {
	mut:
	pos Vec = {x : block_size y: block_size}
	color tui.Color = green
	facing Orientation = .top
}

struct Snake {
	mut: 
	app &App
	direction Orientation
	body []BodyPart
}

fn (s Snake) length() int {
	return s.body.len
}

fn (mut s Snake) move(direction Orientation) {
	s.direction = direction
	
	mut i := s.body.len-1
	
	for i >= 0 {
		mut piece := s.body[i]
		
		if i > 0 { 
			piece.pos = s.body[i-1].pos
			piece.facing = s.body[i-1].facing
		} else {
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
		}
		
		s.body[i] = piece
		i--
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
	
	s.body << BodyPart{ pos : pos, facing : head.facing }
}

fn (s Snake) get_body() []BodyPart {
	return s.body
}

fn (s Snake) get_head() BodyPart {
	return s.body[0]
}

fn (s Snake) get_tail() BodyPart {
	return s.body[s.body.len-1]
}

struct Rat {
mut:
	pos Vec = {x : block_size, y : block_size}
	captured bool = false
	color tui.Color = grey
	app &App
}

fn (mut r Rat) randomize() {
	r.pos.x = rand.int_in_range(block_size, r.app.width-block_size)
	r.pos.y = rand.int_in_range(block_size, r.app.height-block_size)
}


struct App {
mut:
	tui      &tui.Context = 0
	snake    Snake
	rat      Rat
	width    int
	height   int
	redraw   bool = true
}

fn init(x voidptr) {
	mut app := &App(x)
	w, h := app.tui.window_width, app.tui.window_height
	app.width = w
	app.height = h
	
	mut snake := Snake{ body : []BodyPart{len: 1, init: BodyPart{}} app: app}
	mut rat := Rat{app: app}
	rat.randomize()
	app.snake = snake
	app.rat = rat
}

fn event(e &tui.Event, x voidptr) {
	mut app := &App(x)
	match e.typ {
		.mouse_down {
			
		}
		.mouse_drag {
			
		} .mouse_up {
			
		} .key_down {
			match e.code {
				.up, .w { app.move_snake(.top) }
				.down, .s { app.move_snake(.bottom) }
				.left, .a { app.move_snake(.left) }
				.right, .d { app.move_snake(.right) }
				.c {}
				.escape { exit(0) }
				else { exit(0) }
			}
			if e.code == .c { }//app.rects.clear() }
			else if e.code == .escape { exit(0) }
		} else {}
	}
	app.redraw = true
}

fn frame(x voidptr) {
	mut app := &App(x)
	if !app.redraw { return }

	app.tui.clear()
	app.draw_score()
	app.draw_rat()
	app.draw_snake()
	
	if app.check_capture() {
		app.rat.randomize()
		app.snake.grow()
	}
	
	app.tui.reset_bg_color()
	app.tui.flush()
	app.redraw = false
}

fn (mut a App) move_snake(direction Orientation) {
	a.snake.move(direction)
}

fn (mut a App) draw_snake() {
	for part in a.snake.get_body(){
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
	
	return snake_pos.x < rat_pos.x + block_size && snake_pos.x + block_size > rat_pos.x && snake_pos.y < rat_pos.y + block_size && snake_pos.y + block_size > rat_pos.y
}

fn (mut a App) draw_score() {
	a.tui.set_bg_color(grey)
	a.tui.set_color(blue)
	
	score := a.snake.length() - 1
	a.tui.draw_text(a.width - (2 * block_size), block_size, '${score:03d}')
}

mut app := &App{}
app.tui = tui.init(
	user_data: app,
	event_fn: event,
	frame_fn: frame,
	init_fn: init
	hide_cursor: true
	frame_rate: 60
)

app.tui.run()
