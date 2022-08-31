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
// WINDOW_FLAGS  :: SDL.WINDOW_FULLSCREEN_DESKTOP

PLAYER_IDX :: 0
TILE_WIDTH :: 50
TILE_HEIGHT :: 50

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
	grasses: [dynamic]Entity,

	base_velocity: f64,
	velocity: f64,

	// map
	world: [9][17]int,


	grass_img: ^SDL.Surface,
	grass_tex: ^SDL.Texture,

	// main player
	player_img: ^SDL.Surface,
	player_tex: ^SDL.Texture,

	// movement
	moving_left: bool,
	moving_right: bool,
	moving_up: bool,
	moving_down: bool,

	player_moving_left: [3]SDL.Rect,
	player_moving_right: [3]SDL.Rect,
	player_moving_up: [3]SDL.Rect,
	player_moving_down: [3]SDL.Rect,

	// time
	now_time: f64,
	prev_time: f64,
	delta_time: f64,

}

ctx := CTX{
	game_over = false,
	base_velocity =  400,
	velocity =  400,
	grasses = make([dynamic]Entity, 0, WINDOW_W * WINDOW_H),
	perf_frequency = f64(SDL.GetPerformanceFrequency())
}

main :: proc()
{
	fmt.println(ctx.world)
	ctx.world[0] = [17]int{1, 1, 1, 1,  1, 1, 1, 1,  0, 1, 1, 1,  1, 1, 1, 1,  1}
	ctx.world[1] = [17]int{1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1}
	ctx.world[2] = [17]int{1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1}
	ctx.world[3] = [17]int{1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1}
	ctx.world[4] = [17]int{1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1}
	ctx.world[5] = [17]int{1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1}
	ctx.world[6] = [17]int{1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1}
	ctx.world[7] = [17]int{1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1}
	ctx.world[8] = [17]int{1, 1, 1, 1,  1, 1, 1, 1,  0, 1, 1, 1,  1, 1, 1, 1,  1}

	fmt.println(ctx.world)
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

    	update_and_render()

    	render()

	}
}

update_and_render :: proc()
{
	player := &ctx.entities[PLAYER_IDX]

	animation_speed := (SDL.GetTicks() / 175)
	player_animation_idx := animation_speed %% 3

	for e, _ in &ctx.grasses
	{
		SDL.RenderCopy(ctx.renderer, e.tex, &e.source, &e.dest)
	}

	// SDL.SetRenderDrawColor(ctx.renderer, 255, 0, 0, 100)
	// SDL.RenderDrawRect(ctx.renderer, &SDL.Rect{100,100,20,20})
	// SDL.RenderFillRect(ctx.renderer, &SDL.Rect{
		// 100, 100, 20, 20
		// })

	// TODO:: render map
	for row, row_idx in ctx.world
	{

		y := TILE_HEIGHT * (row_idx + 1)

		for col, col_idx in row
		{
			x := TILE_WIDTH * (col_idx + 1)

			if col == 1
			{
				drawRect(x, y, TILE_WIDTH, TILE_HEIGHT, 1, 1, 1) // white
			}
			else
			{
				drawRect(x, y, TILE_WIDTH, TILE_HEIGHT, 0, 0, 0) // black
			}
		}
	}


	// Player
	{

		if ctx.moving_left
		{
			new_x := player.dest.x - i32(ctx.velocity * ctx.delta_time)

			if new_x > 0
			{
				player.source = ctx.player_moving_left[player_animation_idx]
				player.dest.x = new_x
			}
		}

		if ctx.moving_right
		{
			new_x := player.dest.x + i32(ctx.velocity * ctx.delta_time)

			if new_x < (WINDOW_W - 32)
			{
				player.source = ctx.player_moving_right[player_animation_idx]
				player.dest.x = new_x
			}
		}

		if ctx.moving_up
		{
			new_y := player.dest.y - i32(ctx.velocity * ctx.delta_time)

			if new_y > 0
			{
				player.source = ctx.player_moving_up[player_animation_idx]
				player.dest.y = new_y
			}
		}

		if ctx.moving_down
		{
			new_y := player.dest.y + i32(ctx.velocity * ctx.delta_time)

			if new_y < (WINDOW_H - 32)
			{
				player.source = ctx.player_moving_down[player_animation_idx]
				player.dest.y = new_y
			}
		}

		if (ctx.moving_left && ctx.moving_right) || (ctx.moving_up && ctx.moving_down)
		{
			// standing still
			// TODO:: implement a curious / shrug / tapping feet animation
			player.source = ctx.player_moving_down[1]
		}

		SDL.RenderCopy(ctx.renderer, player.tex, &player.source, &player.dest)

	} // END Player movement
}


drawRect :: proc(x, y, w, h: int, r, g, b: f64)
{
	red := u8(255 * r)
	green := u8(255 * g)
	blue := u8(255 * b)

	SDL.SetRenderDrawColor(ctx.renderer, red, green, blue, 100)
	SDL.RenderFillRect(ctx.renderer, &SDL.Rect{
		i32(x), i32(y), i32(w), i32(h)
		})

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

	    // ??
		// SDL.SetRenderDrawBlendMode(ctx.renderer, SDL.BlendMode.BLEND)
	}

}

create_resources :: proc()
{


	ctx.grass_img = SDL_Image.Load("assets/sprites/tilesets/grass.png")
	ctx.grass_tex = SDL.CreateTextureFromSurface(ctx.renderer, ctx.grass_img)

	for y in 1..=WINDOW_H
	{
		for x in 1..=WINDOW_W
		{

			g := Entity{
				tex = ctx.grass_tex,
				source = SDL.Rect{
					x = 0,
					y = 0,
					w = 16,
					h = 16,
				},
				dest = SDL.Rect{
					x = i32(x * 16) - 16,
					y = i32(y * 16) - 16,
					w = 32,
					h = 32,
				}
			}

			append(&ctx.grasses, g)
		}
	}



	ctx.player_img = SDL_Image.Load("assets/bardo.bmp")
	ctx.player_tex = SDL.CreateTextureFromSurface(ctx.renderer, ctx.player_img)

	player_width : i32 = 24
	player_height : i32 = 38

	player := Entity{
		tex = ctx.player_tex,
		source = SDL.Rect{
			x = 0,
			y = 0,
			w = 24,
			h = 38,
		},
		dest = SDL.Rect{
			x = (WINDOW_W / 2) - 32,
			y = WINDOW_H / 2,
			w = player_width * 2,
			h = player_height * 2,
		},
		alive_until = -1

	}

	ctx.entities[PLAYER_IDX] = player

	// left
	ctx.player_moving_left[0] = SDL.Rect{
		x = 0,
		y = 36,
		w = 24,
		h = 38,
	}


	ctx.player_moving_left[1] = SDL.Rect{
		x = 25,
		y = 36,
		w = 24,
		h = 38,
	}


	ctx.player_moving_left[2] = SDL.Rect{
		x = 50,
		y = 36,
		w = 24,
		h = 38,
	}

	// right
	ctx.player_moving_right[0] = SDL.Rect{
		x = 0,
		y = 72,
		w = 24,
		h = 38,
	}


	ctx.player_moving_right[1] = SDL.Rect{
		x = 25,
		y = 72,
		w = 24,
		h = 38,
	}


	ctx.player_moving_right[2] = SDL.Rect{
		x = 50,
		y = 72,
		w = 24,
		h = 38,
	}



	// up
	ctx.player_moving_up[0] = SDL.Rect{
		x = 0,
		y = 110,
		w = 24,
		h = 38,
	}


	ctx.player_moving_up[1] = SDL.Rect{
		x = 25,
		y = 110,
		w = 24,
		h = 38,
	}


	ctx.player_moving_up[2] = SDL.Rect{
		x = 50,
		y = 110,
		w = 24,
		h = 38,
	}


	// down
	ctx.player_moving_down[0] = SDL.Rect{
		x = 0,
		y = 0,
		w = 24,
		h = 38,
	}


	ctx.player_moving_down[1] = SDL.Rect{
		x = 25,
		y = 0,
		w = 24,
		h = 38,
	}


	ctx.player_moving_down[2] = SDL.Rect{
		x = 50,
		y = 0,
		w = 24,
		h = 38,
	}

}

render :: proc()
{


	for e, _ in &ctx.entities
	{
		if e.alive_until > 0 || e.alive_until == -1
		{
			// Casey says he handles the rendering in the update
			// step if he can help it. That is, he recommends NOT
			// assuming that updates and renders need to happen in a separate step.
			// and by "render()" we mean RenderCopy, not the actual Present()
			SDL.RenderCopy(ctx.renderer, e.tex, &e.source, &e.dest)
		}
	}

	// actual flipping / presentation of the copy
	// read comments here :: https://wiki.libsdl.org/SDL_RenderCopy
	SDL.RenderPresent(ctx.renderer)

	// clear the old renderer
	SDL.RenderClear(ctx.renderer)
}

