package main

import "core:fmt"
import "core:runtime"
import "core:math/rand"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

WINDOW_TITLE :: "Some Game Title"
WINDOW_X : i32 = SDL.WINDOWPOS_UNDEFINED // centered
WINDOW_Y : i32 = SDL.WINDOWPOS_UNDEFINED
WINDOW_W : i32 = 1200
WINDOW_H : i32 = 1000
WINDOW_FLAGS  :: SDL.WINDOW_SHOWN // force show on screen

CHAR_IDX :: 0

Entity :: struct
{
	tex: ^SDL.Texture,
	source: SDL.Rect,
	dest: SDL.Rect,
	alive_until: f64, // -1 forever, 0 dead
}

CTX :: struct
{
	perf_frequency: f64,

	game_over: bool,

	window: ^SDL.Window,
	renderer: ^SDL.Renderer,

	entities: [1]Entity,

	base_velocity: f64,
	velocity: f64,

	// main char
	char_img: ^SDL.Surface,
	char_tex: ^SDL.Texture,

	// movement
	moving_left: bool,
	moving_right: bool,
	moving_up: bool,
	moving_down: bool,

	char_moving_left: [3]SDL.Rect,
	char_moving_right: [3]SDL.Rect,
	char_moving_up: [3]SDL.Rect,
	char_moving_down: [3]SDL.Rect,

	// time
	now_time: f64,
	prev_time: f64,
	delta_time: f64,

}

ctx := CTX{
	game_over = false,
	base_velocity =  400,
	velocity =  400,
	perf_frequency = f64(SDL.GetPerformanceFrequency())
}

main :: proc()
{
	init_sdl()

	create_resources()

	loop()

	SDL.DestroyWindow(ctx.window)
	SDL.Quit()

}

loop :: proc()
{

	ctx.now_time = f64(SDL.GetPerformanceCounter()) / ctx.perf_frequency
	SDL.Delay(1)
    ctx.prev_time = f64(SDL.GetPerformanceCounter()) / ctx.perf_frequency
	ctx.delta_time =  ctx.now_time - ctx.prev_time

	event : SDL.Event

	frame := 0

	for !ctx.game_over
	{

	    ctx.now_time = f64(SDL.GetPerformanceCounter()) / f64(SDL.GetPerformanceFrequency())
	    ctx.delta_time = ctx.now_time - ctx.prev_time
	    ctx.prev_time = ctx.now_time

		state := SDL.GetKeyboardState(nil)

		ctx.moving_left = state[SDL.Scancode.A] > 0
		ctx.moving_right = state[SDL.Scancode.D] > 0
		ctx.moving_up = state[SDL.Scancode.W] > 0
		ctx.moving_down = state[SDL.Scancode.S] > 0

    	if SDL.PollEvent(&event)
    	{
    		if event.type == SDL.EventType.QUIT
    		{
    			ctx.game_over = true
    		}

			if event.type == SDL.EventType.KEYDOWN
			{
				#partial switch event.key.keysym.scancode
				{
					case .L:
						fmt.println("Log:")
						for e, _ in ctx.entities
						{
							fmt.println(e)
						}
					case .SPACE:
						fmt.println("Space")
				}

			}

			if event.type == SDL.EventType.KEYUP
			{
			}

    	}

    	process_inputs(frame)

    	render()

    	frame += 1

    	if frame / 3 >= 3
    	{
    		frame = 0
    	}
	}
}

process_inputs :: proc(frame: int)
{
	char := &ctx.entities[CHAR_IDX]

	animation_speed := (SDL.GetTicks() / 175)
	char_animation_idx := animation_speed %% 3

	if ctx.moving_left
	{
		new_x := char.dest.x - i32(ctx.velocity * ctx.delta_time)

		if new_x > 0
		{
			char.source = ctx.char_moving_left[char_animation_idx]
			char.dest.x = new_x
		}
	}

	if ctx.moving_right
	{
		new_x := char.dest.x + i32(ctx.velocity * ctx.delta_time)

		if new_x < (WINDOW_W - 32)
		{
			char.source = ctx.char_moving_right[char_animation_idx]
			char.dest.x = new_x
		}
	}

	if ctx.moving_up
	{
		new_y := char.dest.y - i32(ctx.velocity * ctx.delta_time)

		if new_y > 0
		{
			char.source = ctx.char_moving_up[char_animation_idx]
			char.dest.y = new_y
		}
	}

	if ctx.moving_down
	{
		new_y := char.dest.y + i32(ctx.velocity * ctx.delta_time)

		if new_y < (WINDOW_H - 32)
		{
			char.source = ctx.char_moving_down[char_animation_idx]
			char.dest.y = new_y
		}
	}

	if (ctx.moving_left && ctx.moving_right) || (ctx.moving_up && ctx.moving_down)
	{
		// standing still
		// TODO:: implement a curious / shrug / tapping feet animation
		char.source = ctx.char_moving_down[1]
	}


}

init_sdl :: proc()
{

    SDL.Init(SDL.INIT_EVERYTHING)
	SDL_Image.Init(SDL_Image.INIT_PNG)


	// INIT Resources
	{

	    ctx.window = SDL.CreateWindow(WINDOW_TITLE, WINDOW_X, WINDOW_Y, WINDOW_W, WINDOW_H, WINDOW_FLAGS)

	    ctx.renderer = SDL.CreateRenderer(
	    	ctx.window,
	    	-1,
	    	SDL.RENDERER_PRESENTVSYNC | SDL.RENDERER_ACCELERATED | SDL.RENDERER_TARGETTEXTURE
		)

	}

}

create_resources :: proc()
{
	ctx.char_img = SDL_Image.Load("assets/bardo.bmp")
	ctx.char_tex = SDL.CreateTextureFromSurface(ctx.renderer, ctx.char_img)

	char := Entity{
		tex = ctx.char_tex,
		source = SDL.Rect{
			x = 0,
			y = 0,
			w = 24,
			h = 38,
		},
		dest = SDL.Rect{
			x = (WINDOW_W / 2) - 32,
			y = WINDOW_H / 2,
			w = 72,
			h = 117,
		},
		alive_until = -1

	}

	ctx.entities[CHAR_IDX] = char

	// left
	ctx.char_moving_left[0] = SDL.Rect{
		x = 0,
		y = 36,
		w = 24,
		h = 38,
	}


	ctx.char_moving_left[1] = SDL.Rect{
		x = 25,
		y = 36,
		w = 24,
		h = 38,
	}


	ctx.char_moving_left[2] = SDL.Rect{
		x = 50,
		y = 36,
		w = 24,
		h = 38,
	}

	// right
	ctx.char_moving_right[0] = SDL.Rect{
		x = 0,
		y = 72,
		w = 24,
		h = 38,
	}


	ctx.char_moving_right[1] = SDL.Rect{
		x = 25,
		y = 72,
		w = 24,
		h = 38,
	}


	ctx.char_moving_right[2] = SDL.Rect{
		x = 50,
		y = 72,
		w = 24,
		h = 38,
	}



	// up
	ctx.char_moving_up[0] = SDL.Rect{
		x = 0,
		y = 110,
		w = 24,
		h = 38,
	}


	ctx.char_moving_up[1] = SDL.Rect{
		x = 25,
		y = 110,
		w = 24,
		h = 38,
	}


	ctx.char_moving_up[2] = SDL.Rect{
		x = 50,
		y = 110,
		w = 24,
		h = 38,
	}


	// down
	ctx.char_moving_down[0] = SDL.Rect{
		x = 0,
		y = 0,
		w = 24,
		h = 38,
	}


	ctx.char_moving_down[1] = SDL.Rect{
		x = 25,
		y = 0,
		w = 24,
		h = 38,
	}


	ctx.char_moving_down[2] = SDL.Rect{
		x = 50,
		y = 0,
		w = 24,
		h = 38,
	}

}

render :: proc()
{

	SDL.RenderClear(ctx.renderer)

	for e, _ in &ctx.entities
	{
		if e.alive_until > 0 || e.alive_until == -1
		{
			SDL.RenderCopy(ctx.renderer, e.tex, &e.source, &e.dest)
		}
	}

	SDL.RenderPresent(ctx.renderer)
}

